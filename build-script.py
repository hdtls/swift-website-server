#!/usr/bin/env python3

"""
The ultimate tool for building books.
"""

from __future__ import absolute_import, print_function

import argparse
from itertools import product
import os
import subprocess
import sys


PACKAGE_DIR = os.path.dirname(os.path.realpath(__file__))
LIBRARY_DIR = os.path.join(PACKAGE_DIR, "Sources", "Backend")
PACKAGE_NAME = "swift-blog"
PRODUCT_NAME = "swift-blog"
TOOLCHAIN = "/usr"

GYB_EXEC = os.path.join(PACKAGE_DIR, "utils", "gyb")

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


def printerr(message):
    print(message, file=sys.stderr)


def fatal_error(message):
    printerr(message)
    sys.exit(1)


def escape_cmd_arg(arg):
    if '"' in arg or " " in arg:
        return '"%s"' % arg.replace('"', '\\"')
    else:
        return arg


def mkdirs_if_needed(path):
    if not os.path.exists(path):
        os.makedirs(path)


def call(cmd, verbose, env=os.environ, stdout=None):
    if verbose:
        print(" ".join([escape_cmd_arg(arg) for arg in cmd]))

    return subprocess.call(cmd, env=env, stdout=stdout, stderr=subprocess.STDOUT)


def check_call(cmd, verbose, cwd=None, env=os.environ):
    if verbose:
        print(" ".join([escape_cmd_arg(arg) for arg in cmd]))
    return subprocess.check_call(cmd, cwd=cwd, env=env, stderr=subprocess.STDOUT)


def check_gyb_exec(gyb_exec):
    if not os.path.exists(gyb_exec):
        fatal_error(
            """
Error: Could not find gyb.
Looking at '%s'.
"""
            % gyb_exec
        )


def generate_xcodeproj(config):
    print("Generate {} as an Xcode project".format(PRODUCT_NAME))
    os.chdir(PACKAGE_DIR)
    popenargs = ["swift", "package", "generate-xcodeproj"]

    if config:
        popenargs.extend(["--xcconfig-overrides", config])
    check_call(popenargs)


def generate_single_gyb_file(
    exec,
    input_file,
    output_file_name,
    destination,
    verbose,
    other_flags=[],
):
    gyb_command = [
        sys.executable,
        exec,
        input_file,
        "--line-directive=",
        "-o",
        os.path.join(destination, output_file_name),
    ]

    gyb_command += other_flags

    check_call(gyb_command, verbose=verbose)


def generate_gyb_files(gyb_exec, verbose, destination=None):
    if verbose:
        print("Planning generate files")
    print("Generating files...")
    check_gyb_exec(gyb_exec)

    if not destination:
        destination = os.path.join(LIBRARY_DIR, "autogenerated")

    mkdirs_if_needed(destination)

    remove_autogenerated_files(destination)

    # Auto generate files that defined in gyb file.
    sources_dir = LIBRARY_DIR
    for file_name in os.listdir(sources_dir):
        if not file_name.endswith(".gyb"):
            continue

        path = os.path.join(sources_dir, file_name)

        # Slice off the '.gyb' to get the name for the output file
        output_file_name = file_name[:-4]

        generate_single_gyb_file(
            gyb_exec,
            path,
            output_file_name,
            destination,
            verbose=verbose,
        )

    # Auto generate files that defined in gyb template.
    for kind in BASE_KIND_FILES:
        path = os.path.join(LIBRARY_DIR, "Fluent.swift.gyb.template")

        generate_single_gyb_file(
            gyb_exec,
            path,
            kind + ".swift",
            destination,
            other_flags=["-DEMIT_KIND=%s" % kind],
            verbose=verbose,
        )

    print("Generate complete!")


def remove_autogenerated_files(cwd, verbose=False):
    for path in filter(lambda p: p.endswith(".swift"), os.listdir(cwd)):
        check_call(["rm", path], cwd=cwd, verbose=verbose)


def get_swiftpm_invocation(toolchain, action, configuration):
    swift_exec = os.path.join(toolchain, "bin", "swift")

    popenargs = [swift_exec, action]
    popenargs.extend(["--package-path", PACKAGE_DIR])
    popenargs.extend(["--configuration", configuration])

    return popenargs


def run_tests(toolchain, configuration, verbose):
    if verbose:
        print("Planning run tests")
    print("Running tests for product {}".format(PRODUCT_NAME))

    success = run_xctests(
        toolchain=toolchain,
        configuration=configuration,
        verbose=verbose,
    )

    return success


def run_xctests(toolchain, configuration, verbose):
    swiftpm_call = get_swiftpm_invocation(
        toolchain=toolchain,
        action="test",
        configuration=configuration,
    )

    if verbose:
        swiftpm_call.extend(["--verbose"])

    swiftpm_call.extend(["--test-product", "{}PackageTests".format(PACKAGE_NAME)])

    return call(swiftpm_call, verbose=verbose) == 0


# -----------------------------------------------------------------------------
# Arugment Parsing

_DESCRIPTION = """
Build and test script for {0}.

Build {0} by generating all necessary files form the corresponding
.swift.gyb files first.

It is not necessary to build the compiler project.

The build script can also drive the test suite included in the {0}
repo. This requires a custom build of the compiler project since it accesses
test utilities that are not shipped as part of the toolchains. See the Testing
section for arguments that need to be specified for this.
""".format(
    PRODUCT_NAME
)


def parse_args():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter, description=_DESCRIPTION
    )

    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Enable verbose logging."
    )

    xcode_project_group = parser.add_argument_group("Xcode Project")

    xcode_project_group.add_argument(
        "--generate-xcodeproj",
        action="store_true",
        help="Generate an Xcode project for {}.".format(PRODUCT_NAME),
    )

    xcode_project_group.add_argument(
        "--xcconfig-path",
        help="The path to an xcconfig file for generating Xcode projct.",
    )

    build_group = parser.add_argument_group("Build")

    build_group.add_argument(
        "-c", "--configuration", 
        default="debug", 
        help="Build with configuration (default: %(default)s)."
    )

    build_group.add_argument(
        "--degyb-only",
        action="store_true",
        help="The script only generates swift files from gyb and skips the "
        "rest of the build",
    )

    build_group.add_argument(
        "--toolchain",
        default=TOOLCHAIN,
        help="The path to the toolchain that shall be used to build {} (default: %(default)s).".format(
            PRODUCT_NAME
        ),
    )
    
    build_group.add_argument(
        "--static-swift-stdlib",
        action="store_true",
        default=False,
        help="Link Swift stdlib statically (default: %(default)s)."
    )
    
    test_group = parser.add_argument_group("Test")

    test_group.add_argument("-t", "--test", action="store_true", help="Run tests")

    test_group.add_argument(
        "--gyb",
        default=GYB_EXEC,
        help="Path to the gyb tool (default: %(default)s).",
    )

    return parser.parse_args()


def main():
    args = parse_args()

    try:
        generate_gyb_files(args.gyb, verbose=args.verbose)
    except subprocess.CalledProcessError as e:
        printerr("FAIL: Generating .gyb files failed")
        printerr("Executing: %s" % " ".join(e.cmd))
        fatal_error(e.output)

    # Skip the rest of the build if we should perform degyb only
    if args.degyb_only:
        sys.exit(0)

    if args.generate_xcodeproj:
        generate_xcodeproj(config=args.xcconfig_path)
        sys.exit(0)

    try:
        popenargs = get_swiftpm_invocation(args.toolchain, "build", args.configuration)
        if args.verbose:
            popenargs.append("--verbose")
        print("Planing build product " + PRODUCT_NAME)
        popenargs.extend(["--product", PRODUCT_NAME])
        if args.static_swift_stdlib:
            popenargs.append("--static-swift-stdlib")
        check_call(popenargs, args.verbose)
    except subprocess.CalledProcessError as e:
        printerr("FAIL: Building product failed")
        printerr("Executing: %s" % " ".join(e.cmd))
        fatal_error(e.output)

    if args.test:
        try:
            success = run_tests(
                toolchain=args.toolchain,
                configuration=args.configuration,
                verbose=args.verbose,
            )
            if not success:
                # An error message has already been printed by the failing test
                # suite
                sys.exit(1)
            else:
                print("All tests passed!")
        except subprocess.CalledProcessError as e:
            printerr("FAIL: Running tests failed")
            printerr("Executing: %s" % " ".join(e.cmd))
            fatal_error(e.output)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(1)
