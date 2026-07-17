"""Testes offline do pipeline: rodam sem Spark, sem credencial e sem workspace.

Cobrem a classe de erro que o `bundle deploy` NAO pega: o deploy fica verde e o
pipeline so quebra quando roda.
"""

import re
from pathlib import Path

import pytest
import yaml

REPO = Path(__file__).resolve().parent.parent
TRANSFORMATIONS = REPO / "src" / "pipelines" / "bakehouse" / "transformations"
PIPELINE_YML = REPO / "resources" / "bakehouse_pipeline.yml"

PLACEHOLDER = re.compile(r"\$\{([a-z_]+)\}")
CREATE_ALVO = re.compile(
    r"CREATE OR REFRESH (?:STREAMING TABLE|MATERIALIZED VIEW)\s+"
    r"\$\{medallion_catalog\}\.\$\{(\w+)_schema\}\."
)

SQL_FILES = sorted(TRANSFORMATIONS.rglob("*.sql"))
ids = lambda p: str(p.relative_to(TRANSFORMATIONS))  # noqa: E731


def declarados() -> set[str]:
    pipeline = yaml.safe_load(PIPELINE_YML.read_text())
    return set(pipeline["resources"]["pipelines"]["bakehouse_medallion"]["configuration"])


def test_o_glob_do_pipeline_tem_o_que_carregar():
    assert SQL_FILES


@pytest.mark.parametrize("sql", SQL_FILES, ids=ids)
def test_placeholder_do_sql_esta_declarado_no_pipeline(sql):
    """${bronze_shema} com typo deploya sem erro e so morre em runtime."""
    usados = set(PLACEHOLDER.findall(sql.read_text()))
    assert usados <= declarados(), f"nao declarados em configuration: {usados - declarados()}"


@pytest.mark.parametrize("sql", SQL_FILES, ids=ids)
def test_camada_bate_com_a_pasta(sql):
    """O desenho do workshop: o nome do schema E a camada. gold/ so escreve em ${gold_schema}."""
    assert set(CREATE_ALVO.findall(sql.read_text())) == {sql.parent.name}


@pytest.mark.parametrize("sql", SQL_FILES, ids=ids)
def test_sem_catalogo_de_ambiente_hardcoded(sql):
    """O catalogo vem de ${medallion_catalog}. Hardcode faria o prod escrever no dev."""
    texto = sql.read_text()
    assert "bakehouse_dev" not in texto
    assert not re.search(r"\bbakehouse\.(bronze|silver|gold)\b", texto)
