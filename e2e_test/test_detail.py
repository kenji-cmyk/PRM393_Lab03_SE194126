"""Lesson content, source citations and explicit read progress."""
import pytest
from .cases import CASES

pytestmark = pytest.mark.artemis


@pytest.mark.parametrize('case_id', ['LEARN-01', 'LEARN-02'])
def test_learning_flow(run_case, case_id):
    run_case(CASES[case_id])
