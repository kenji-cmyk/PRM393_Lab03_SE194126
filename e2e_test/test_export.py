"""Preview generation and authenticated Cloud Storage report upload."""
import pytest
from .cases import CASES

pytestmark = pytest.mark.artemis


@pytest.mark.parametrize('case_id', ['EXPORT-01', 'EXPORT-02'])
def test_pdf_export(run_case, case_id):
    run_case(CASES[case_id])
