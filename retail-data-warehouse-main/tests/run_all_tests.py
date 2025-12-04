import unittest
import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from test_data_quality import *
from test_relationships import *
from test_row_counts import *
from test_edge_cases import *

if __name__ == '__main__':
    # Run all tests
    unittest.main(verbosity=2)