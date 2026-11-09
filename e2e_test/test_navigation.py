"""All three flow destinations from a fresh preview session."""
import pytest
from .cases import CASES

pytestmark = pytest.mark.artemis


def test_flow_navigation(run_case):
    run_case(CASES['NAV-01'])
