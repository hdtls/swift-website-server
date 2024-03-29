#!/usr/bin/env python3

"""
The ultimate tool for building books.
"""

import argparse
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from typing import List, Literal, Optional, Union


PACKAGE_DIR = Path(".")
LIBRARY_DIR = PACKAGE_DIR.joinpath("Sources", "Backend")
PACKAGE_NAME = "swift-blog"
PRODUCT_NAME = "swift-blog"

GYB_EXEC = PACKAGE_DIR.joinpath("utils", "gyb").as_posix()

BASE_KIND_FILES = [
    "Blog",
    "BlogCategory",
    "Education",
    "Experience",
    "Industry",
    "Project",
    "Skill",
    "SocialNetworking",
    "SocialNetworkingService",
    "User",
]


def printerr(message: object):
    print(message, file=sys.stderr)


def fatal_error(message: object):
    printerr(message)
    sys.exit(1)


def escape_cmd_arg(arg: str):
    if '"' in arg or " " in arg:
        return '"%s"' % arg.replace('"', '\\"')
    else:
        return arg

_CMD = Union[str, List[str]]
_CONFIG = Optional[Literal["debug", "release"]]

def call(cmd: _CMD, verbose: Optional[bool], env=os.environ, stdout: int = None):
    if verbose:
        if isinstance(cmd, str):
            print(escape_cmd_arg(cmd))
        else:
            print(" ".join([escape_cmd_arg(arg) for arg in cmd]))
    return subprocess.call(cmd, env=env, stdout=stdout, stderr=subprocess.STDOUT)


def check_call(cmd: _CMD, verbose: Optional[bool], cwd: Path = None, env=os.environ):
    if verbose:
        if isinstance(cmd, str):
            print(escape_cmd_arg(cmd))
        else:
            print(" ".join([escape_cmd_arg(arg) for arg in cmd]))
    return subprocess.check_call(cmd, cwd=cwd, env=env, stderr=subprocess.STDOUT)


def check_gyb_exec(exec: Optional[str]):
    if not (exec and Path(exec).exists()):
        fatal_error(
            """
Error: Could not find gyb.
Looking at '%s'.
"""
            % exec
        )


def check_rsync():
    with open(os.devnull, "w") as DEVNULL:
        if call(["rsync", "--version"], verbose=False, stdout=DEVNULL) != 0:
            fatal_error("Error: Could not find rsync.")


def generate_xcodeproj():
    print("Generate {} as an Xcode project".format(PRODUCT_NAME))
    os.chdir(PACKAGE_DIR)

    popenargs = ["swift", "package", "generate-xcodeproj"]

    return check_call(popenargs)


def _generate_file_from_gyb_file(
    exec: Union[Path, str],
    input_file: Path,
    output_file_name: str,
    destination: Path,
    temp_files_dir: Path,
    verbose: Optional[bool],
    other_flags: List[str] = [],
):
    if isinstance(exec, Path):
        exec = exec.as_posix()

    popenargs = [
        sys.executable,
        exec,
        input_file.as_posix(),
        "--line-directive=",
        "-o",
        temp_files_dir.joinpath(output_file_name).as_posix(),
    ]

    popenargs += other_flags

    check_call(popenargs, verbose=verbose)

    # Copy the file if different from the file already present in
    # gyb
    popenargs = [
        "rsync",
        "--checksum",
        temp_files_dir.joinpath(output_file_name).as_posix(),
        destination.joinpath(output_file_name).as_posix(),
    ]

    check_call(popenargs, verbose=verbose)


def _generate_files_from_gyb_template(
    exec: Union[Path, str],
    src: Path,
    dst: Path,
    tags: List[str],
    temp_files_dir: Path,
    verbose: Optional[bool],
):
    for tag in tags:
        _generate_file_from_gyb_file(
            exec=exec,
            input_file=src,
            output_file_name=tag + ".swift",
            destination=dst,
            temp_files_dir=temp_files_dir,
            other_flags=["-DEMIT_KIND=%s" % tag],
            verbose=verbose,
        )


def generate_files(exec: Union[Path, str], verbose: Optional[bool]):
    if verbose:
        print("Planning generate files")
    print("Generating files...")

    check_gyb_exec(exec)
    check_rsync()

    temp_files_dir = Path(tempfile.gettempdir())
    temp_files_dir.mkdir(parents=True, exist_ok=True)

    parent = None
    # Auto generate files that defined in gyb file.
    for path in LIBRARY_DIR.rglob("*.gyb"):
        destination = path.parent.joinpath("autogenerated")
        if not destination.exists():
            destination.mkdir(parents=True, exist_ok=True)

        if parent != path.parent:
            _remove_autogenerated_files(path.parent, destination, verbose)
            parent = path.parent

        _generate_file_from_gyb_file(
            exec,
            path,
            path.name[:-4],
            destination,
            temp_files_dir,
            verbose,
        )

    # Auto generate files that defined in gyb template.
    for path in LIBRARY_DIR.rglob("*.gyb.template"):
        destination = path.parent.joinpath("autogenerated")
        if not destination.exists():
            destination.mkdir(parents=True, exist_ok=True)

        if parent != path.parent:
            _remove_autogenerated_files(path.parent, destination, verbose)
            parent = path.parent

        _generate_files_from_gyb_template(
            exec, path, destination, BASE_KIND_FILES, temp_files_dir, verbose
        )

    print("Generate complete!")


# Remove any files in the `gyb` directory that no longer have a
# corresponding `.gyb` file in the `Sources` directory.
def _remove_autogenerated_files(src: Path, dst: Path, verbose: Optional[bool],):
    for dir in dst.glob("*.swift"):
        path = src.joinpath(dir.name, ".gyb")

        if not ((dir.name[:-6] in BASE_KIND_FILES) or path.exists()):
            check_call(["rm", dir], cwd=dst, verbose=verbose)


def swift_execute(
    action: Literal["build", "test"],
    configuration: _CONFIG,
    product: str,
    sanitize: Optional[Literal["address", "thread", "undefined", "scudo"]] = None,
    parallel: bool = False,
    static_stdlib: bool = False,
    verbose: bool = False,
):
    popenargs = ["/usr/bin/swift", action]
    
    popenargs.extend(["--package-path", PACKAGE_DIR.as_posix()])
    
    popenargs.extend(["--configuration", configuration])

    if action == "build":
        popenargs.extend(["--product", product])
    else:
        if product:
            popenargs.extend(["--test-product", product])
    
    if sanitize:
        popenargs.extend(["--sanitize", sanitize])
    
    if action == "test" and parallel:
        popenargs.append("--parallel")
    
    if static_stdlib:
        popenargs.append("--static-swift-stdlib")

    if verbose:
        popenargs.append("--verbose")

    if action == "build":
        print("Planing build product " + product)
    else:
        print("Planning run tests")
        print("Running tests for product {}".format(PRODUCT_NAME))

    return check_call(popenargs, verbose)


# -----------------------------------------------------------------------------
# Arugment Parsing

def parse_args():
    parser = argparse.ArgumentParser(
        usage="python3 build-script.py <options>",
        description="Build and test script for {0}.".format(PRODUCT_NAME)
    )

    parser.add_argument(
        "--gyb-path",
        default=GYB_EXEC,
        help="Path to the gyb tool (default: %(default)s).",
    )

    parser.add_argument(
        "--degyb-only",
        action="store_true",
        help="The script only generates swift files from gyb and skips the "
        "rest of the build",
    )

    parser.add_argument(
        "--generate-xcodeproj",
        action="store_true",
        help="Generate an Xcode project for {}.".format(PRODUCT_NAME),
    )

    parser.add_argument(
        "-c",
        "--configuration",
        default="debug",
        help="Build with configuration (default: %(default)s).",
    )

    parser.add_argument(
        "--sanitize",
        help="Turn on runtime checks for erroneous behavior, possible values: address, thread, undefined, scudo"
    )

    parser.add_argument(
        "--static-swift-stdlib",
        action="store_true",
        default=False,
        help="Link Swift stdlib statically (default: %(default)s).",
    )

    parser.add_argument(
        "--build",
        action="store_true",
        help="Build sources into binary products."
    )

    parser.add_argument("-t", "--test", action="store_true", help="Run tests")

    parser.add_argument(
        "--test-product",
        help="Test the specified product if specified otherwise test all products instead."
    )

    parser.add_argument(
        "--parallel",
        action="store_true",
        help="Run the tests in parallel.",
    )

    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Enable verbose logging."
    )
    
    return parser.parse_args()


def main():
    args = parse_args()

    try:
        generate_files(args.gyb_path, verbose=args.verbose)
    except subprocess.CalledProcessError as e:
        printerr("FAIL: Generating .gyb files failed")
        printerr("Executing: %s" % " ".join(e.cmd))
        fatal_error(e.output)

    # Skip the rest of the build if we should perform degyb only
    if args.degyb_only:
        sys.exit(0)

    if args.generate_xcodeproj:
        sys.exit(generate_xcodeproj())

    if args.build:
        try:
            swift_execute(
                action="build", 
                configuration=args.configuration,
                product=PRODUCT_NAME,
                sanitize=args.sanitize,
                static_stdlib=args.static_swift_stdlib,
                verbose=args.verbose,
            )
        except subprocess.CalledProcessError as e:
            printerr("FAIL: Building product failed")
            printerr("Executing: %s" % " ".join(e.cmd))
            fatal_error(e.output)

    if args.test:
        try:
            success = swift_execute(
                action="test", 
                configuration=args.configuration,
                product=args.test_product,
                sanitize=args.sanitize,
                parallel=args.parallel,
                static_stdlib=args.static_swift_stdlib,
                verbose=args.verbose,
            ) == 0
            if success:
                print("All tests passed!")
            else:
                # An error message has already been printed by the failing test
                # suite
                sys.exit(1)
        except subprocess.CalledProcessError as e:
            printerr("FAIL: Running tests failed")
            printerr("Executing: %s" % " ".join(e.cmd))
            fatal_error(e.output)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(1)
