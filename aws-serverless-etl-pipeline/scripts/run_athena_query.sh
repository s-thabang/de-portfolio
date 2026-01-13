# Helper script to run Athena queries

set -e

if [ -z "$1" ]; then
    echo "Usage: ./run_athena_query.sh \"YOUR SQL QUERY\""
    exit 1
fi

QUERY="$1"

cd ../terraform
DATABASE_NAME=$(terraform output -raw glue_database_name)
WORKGROUP=$(terraform output -raw athena_workgroup_name)
cd ../scripts

echo "Running Athena query..."
echo "Database: $DATABASE_NAME"
echo "Workgroup: $WORKGROUP"
echo ""
echo "Query:"
echo "$QUERY"
echo ""

# Start query execution
EXECUTION_ID=$(aws athena start-query-execution \
    --query-string "$QUERY" \
    --query-execution-context Database=$DATABASE_NAME \
    --work-group $WORKGROUP \
    --region af-south-1 \
    --query 'QueryExecutionId' \
    --output text)

echo "Execution ID: $EXECUTION_ID"
echo "Waiting for query to complete..."

# Wait for query to finish
while true; do
    STATUS=$(aws athena get-query-execution \
        --query-execution-id $EXECUTION_ID \
        --region af-south-1 \
        --query 'QueryExecution.Status.State' \
        --output text)
    
    if [ "$STATUS" = "SUCCEEDED" ]; then
        echo "Query succeeded!"
        break
    elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "CANCELLED" ]; then
        echo "Query failed!"
        aws athena get-query-execution \
            --query-execution-id $EXECUTION_ID \
            --region af-south-1 \
            --query 'QueryExecution.Status.StateChangeReason' \
            --output text
        exit 1
    fi
    
    sleep 2
done

# Get results
echo ""
echo "Results:"
aws athena get-query-results \
    --query-execution-id $EXECUTION_ID \
    --region af-south-1 \
    --query 'ResultSet.Rows[*].Data[*].VarCharValue' \
    --output table

# Show data scanned
DATA_SCANNED=$(aws athena get-query-execution \
    --query-execution-id $EXECUTION_ID \
    --region af-south-1 \
    --query 'QueryExecution.Statistics.DataScannedInBytes' \
    --output text)

echo ""
echo "Data scanned: $(echo "scale=2; $DATA_SCANNED / 1024 / 1024" | bc) MB"
