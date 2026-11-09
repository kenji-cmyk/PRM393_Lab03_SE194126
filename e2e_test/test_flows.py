"""Actual meal entry, validation, idempotent save and genuine empty state."""
import pytest
from .cases import CASES

pytestmark = pytest.mark.artemis


@pytest.mark.parametrize('case_id', ['MEAL-01', 'MEAL-02', 'MEAL-03'])
def test_meal_flow(run_case, case_id):
    run_case(CASES[case_id])
