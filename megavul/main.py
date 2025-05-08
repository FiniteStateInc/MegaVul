import subprocess
import os

from megavul.pipeline.download_cve_from_nvd import crawl_nvd
from megavul.pipeline.extract_and_download_commit import extract_and_download_commit
from megavul.pipeline.extract_commit_diff import extract_commit_diff
from megavul.pipeline.extract_cve_info import extract_cve_info
from megavul.pipeline.extract_graph_and_abstract import extract_graph_and_abstract
from megavul.pipeline.flatten_megavul import generate_megavul
from megavul.util.logging_util import global_logger
from megavul.util.config import crawling_language
from megavul.util.config import crawling_language
from megavul.util.storage import StorageLocation
from tree_sitter import Language


def ensure_tree_sitter_built(language_name: str):
    tree_sitter_name = f'tree-sitter-{language_name}'
    tree_sitter_path = StorageLocation.tree_sitter_dir() / tree_sitter_name
    tree_sitter_so = StorageLocation.result_dir() / 'build' / f'build-{tree_sitter_name}.so'

    if not tree_sitter_so.exists():
        print("Running tree-sitter generate")
        subprocess.call(
            'tree-sitter generate',
            cwd=tree_sitter_path,
            env=os.environ.copy(), shell=True
        )
        print("Building tree-sitter")
        Language.build_library(str(tree_sitter_so), [str(tree_sitter_path)])
    else:
        raise Exception("tree-sitter does not exists")

if __name__ == '__main__':
    global_logger.info(f"MegaVul is now crawling {crawling_language}")

    # step.1 crawl all CVEs from NVD
    crawl_nvd()

    # step.2 find potential commits from reference URLs in each CVE
    extract_cve_info()

    # step.3 download commit from different GIT platforms
    extract_and_download_commit()

    # step.4 using tree-sitter to extract functions and clean dataset using multiple filters
    ensure_tree_sitter_built("c")
    ensure_tree_sitter_built("cpp")
    extract_commit_diff()

    # step.5 using joern to generate graph and generate abstract functions using CodeAbstracter
    extract_graph_and_abstract()

    # step.6 generate the final dataset
    generate_megavul()
