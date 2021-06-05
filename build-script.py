#!/usr/bin/env python

"""
The ultimate tool for building books.
"""

from __future__ import absolute_import, print_function

import argparse
import os
import platform
import subprocess
import sys
import tempfile

# -----------------------------------------------------------------------------
# Constants

PACKAGE_DIR = os.path.dirname(os.path.realpath(__file__))
LIBRARY_DIR = os.path.join(PACKAGE_DIR, "Sources", "App")
PACKAGE_NAME = "swift-website-server"
PRODUCT_NAME = "Run"
TOOLCHAIN = "/usr"

GYB_EXEC = os.path.join(PACKAGE_DIR, "utils", "gyb")
LINUX_TESTS_GENERATOR = os.path.join(PACKAGE_DIR, "utils", "generate_linux_tests.py")

BASE_KIND_FILES = {
    "Blog": "Blog.swift",
    "BlogCategory": "BlogCategory.swift",
    "Education": "Education.swift",
    "Experience": "Experience.swift",
    "Industry": "Industry.swift",
    "Project": "Project.swift",
    "Skill": "Skill.swift",
    "SocialNetworking": "SocialNetworking.swift",
    "SocialNetworkingService": "SocialNetworkingService.swift",
    "User": "User.swift"
}


# -----------------------------------------------------------------------------
# Xcode Projects Generation


def generate_xcodeproj(config):
    print("** Generate {} as an Xcode project **".format(PRODUCT_NAME))
    os.chdir(PACKAGE_DIR)
    swiftpm_call = ["swift", "package", "generate-xcodeproj"]
    if config:
        swiftpm_call.extend(["--xcconfig-overrides", config])
    check_call(swiftpm_call)


# -----------------------------------------------------------------------------
# Helpers


def printerr(message):
    print(message, file=sys.stderr)


def fatal_error(message):
    printerr(message)
    sys.exit(1)


def escapeCmdArg(arg):
    if '"' in arg or " " in arg:
        return '"%s"' % arg.replace('"', '\\"')
    else:
        return arg


def call(cmd, env=os.environ, stdout=None, stderr=subprocess.STDOUT, verbose=False):
    if verbose:
        print(" ".join([escapeCmdArg(arg) for arg in cmd]))
    process = subprocess.Popen(cmd, env=env, stdout=stdout, stderr=stderr)
    process.wait()

    return process.returncode


def check_call(cmd, cwd=None, env=os.environ, verbose=False):
    if verbose:
        print(" ".join([escapeCmdArg(arg) for arg in cmd]))
    return subprocess.check_call(cmd, cwd=cwd, env=env, stderr=subprocess.STDOUT)


def realpath(path):
    if path is None:
        return None
    return os.path.realpath(path)


# -----------------------------------------------------------------------------
# Generating gyb Files


def check_gyb_exec(gyb_exec):
    if not os.path.exists(gyb_exec):
        fatal_error(
            """
Error: Could not find gyb.
Looking at '%s'.

Make sure you have the main swift repo checked out next to the swift-syntax
repository.
Refer to README.md for more information.
"""
            % gyb_exec
        )


def check_rsync():
    with open(os.devnull, "w") as DEVNULL:
        if call(["rsync", "--version"], stdout=DEVNULL) != 0:
            fatal_error("Error: Could not find rsync.")


def check_linux_tests_generator(linux_tests_generator):
    if not os.path.exists(linux_tests_generator):
        fatal_error(
            """
Error: Could not find tests generator.
Looking at '%s'.
"""
            % linux_tests_generator
        )


def generate_single_gyb_file(
    gyb_exec,
    gyb_file,
    output_file_name,
    destination,
    temp_files_dir,
    add_source_locations,
    additional_gyb_flags,
    verbose,
):
    # Source locations are added by default by gyb, and cleared by passing
    # `--line-directive=` (nothing following the `=`) to the generator. Our
    # flag is the reverse; we don't want them by default, only if requested.
    line_directive_flags = [] if add_source_locations else ["--line-directive="]

    # Generate the new file
    gyb_command = [
        sys.executable,
        gyb_exec,
        gyb_file,
        "-o",
        os.path.join(temp_files_dir, output_file_name),
    ]
    gyb_command += line_directive_flags
    gyb_command += additional_gyb_flags

    check_call(gyb_command, verbose=verbose)

    # Copy the file if different from the file already present in
    # gyb
    rsync_command = [
        "rsync",
        "--checksum",
        os.path.join(temp_files_dir, output_file_name),
        os.path.join(destination, output_file_name),
    ]

    check_call(rsync_command, verbose=verbose)


def generate_gyb_files(gyb_exec, verbose, add_source_locations, destination=None):
    print("** Generating gyb Files **")

    check_gyb_exec(gyb_exec)
    check_rsync()

    temp_files_dir = tempfile.gettempdir()

    if destination is None:
        destination = os.path.join(LIBRARY_DIR, "gyb")

    template_destination = os.path.join(destination, "Models")

    make_dir_if_needed(temp_files_dir)
    make_dir_if_needed(destination)
    make_dir_if_needed(template_destination)

    # Clear any *.swift files that are relics from the previous run.
    clear_gyb_files_from_previous_run(LIBRARY_DIR, destination)

    for previous_gyb_gen_file in os.listdir(template_destination):
        if previous_gyb_gen_file.endswith(".swift"):
            if previous_gyb_gen_file not in BASE_KIND_FILES.values():
                check_call(
                    ["rm", previous_gyb_gen_file],
                    cwd=template_destination,
                    verbose=verbose,
                )

    generate_gyb_files_helper(
        gyb_exec,
        LIBRARY_DIR,
        destination,
        temp_files_dir,
        add_source_locations,
        verbose,
    )

    for base_kind in BASE_KIND_FILES:
        output_file_name = BASE_KIND_FILES[base_kind]

        gyb_file = os.path.join(LIBRARY_DIR, "Fluent.swift.gyb.template")

        generate_single_gyb_file(
            gyb_exec,
            gyb_file,
            output_file_name,
            template_destination,
            temp_files_dir,
            add_source_locations,
            additional_gyb_flags=["-DEMIT_KIND=%s" % base_kind],
            verbose=verbose,
        )

    print("Done Generating gyb Files")


def make_dir_if_needed(path):
    if not os.path.exists(path):
        os.makedirs(path)


# Remove any files in the `gyb` directory that no longer have a
# corresponding `.gyb` file in the `Sources` directory.
def clear_gyb_files_from_previous_run(sources_dir, destination_dir, verbose=False):
    for previous_gyb_gen_file in os.listdir(destination_dir):
        if previous_gyb_gen_file.endswith(".swift"):
            gyb_file = os.path.join(sources_dir, previous_gyb_gen_file + ".gyb")
            if not os.path.exists(gyb_file):
                check_call(
                    ["rm", previous_gyb_gen_file], cwd=destination_dir, verbose=verbose
                )


# Generate the new .swift files in `temp_files_dir` and only copy them
# to `destiantion_dir` if they are different than the
# files already residing there. This way we don't touch the generated .swift
# files if they haven't changed and don't trigger a rebuild.
def generate_gyb_files_helper(
    gyb_exec,
    sources_dir,
    destination_dir,
    temp_files_dir,
    add_source_locations,
    verbose,
):
    for gyb_file in os.listdir(sources_dir):
        if not gyb_file.endswith(".gyb"):
            continue

        gyb_file_path = os.path.join(sources_dir, gyb_file)

        # Slice off the '.gyb' to get the name for the output file
        output_file_name = gyb_file[:-4]

        generate_single_gyb_file(
            gyb_exec,
            gyb_file_path,
            output_file_name,
            destination_dir,
            temp_files_dir,
            add_source_locations,
            additional_gyb_flags=[],
            verbose=verbose,
        )


# -----------------------------------------------------------------------------
# Building


def get_swiftpm_invocation(toolchain, action, build_dir, multiroot_data_file, release):
    swift_exec = os.path.join(toolchain, "bin", "swift")

    swiftpm_call = [swift_exec, action]
    swiftpm_call.extend(["--package-path", PACKAGE_DIR])
    if platform.system() != "Darwin":
        swiftpm_call.extend(["--enable-test-discovery"])
    if release:
        swiftpm_call.extend(["--configuration", "release"])
    if build_dir:
        swiftpm_call.extend(["--build-path", build_dir])
    if multiroot_data_file:
        swiftpm_call.extend(["--multiroot-data-file", multiroot_data_file])

    return swiftpm_call


class Builder(object):
    def __init__(
        self,
        toolchain,
        build_dir,
        multiroot_data_file,
        release,
        verbose,
        disable_sandbox=False,
    ):
        self.swiftpm_call = get_swiftpm_invocation(
            toolchain=toolchain,
            action="build",
            build_dir=build_dir,
            multiroot_data_file=multiroot_data_file,
            release=release,
        )
        if disable_sandbox:
            self.swiftpm_call.append("--disable-sandbox")
        if verbose:
            self.swiftpm_call.extend(["--verbose"])
        self.verbose = verbose

    def build(self, product_name):
        print("** Building " + product_name + " **")
        command = list(self.swiftpm_call)
        command.extend(["--product", product_name])

        env = dict(os.environ)
        env["SWIFT_BUILD_SCRIPT_ENVIRONMENT"] = "1"
        # Tell other projects in the unified build to use local dependencies
        env["SWIFTCI_USE_LOCAL_DEPS"] = "1"
        check_call(command, env=env, verbose=self.verbose)


# -----------------------------------------------------------------------------
# Testing


def verify_generated_files(gyb_exec, verbose):
    user_swiftsyntax_generated_dir = os.path.join(LIBRARY_DIR, "gyb")

    self_swiftsyntax_generated_dir = tempfile.mkdtemp()

    generate_gyb_files(
        gyb_exec,
        verbose=verbose,
        add_source_locations=False,
        destination=self_swiftsyntax_generated_dir,
    )

    check_generated_files_match(
        self_swiftsyntax_generated_dir, user_swiftsyntax_generated_dir
    )


def check_generated_files_match(self_generated_dir, user_generated_dir):
    command = [
        "diff",
        "-r",
        "-x",
        ".*",  # Exclude dot files like .DS_Store
        "--context=0",
        self_generated_dir,
        user_generated_dir,
    ]
    check_call(command)


def run_tests(
    toolchain, build_dir, multiroot_data_file, release, filecheck_exec, verbose
):
    print("** Running {} Tests **".format(PRODUCT_NAME))

    xctest_success = run_xctests(
        toolchain=toolchain,
        build_dir=build_dir,
        multiroot_data_file=multiroot_data_file,
        release=release,
        verbose=verbose,
    )
    if not xctest_success:
        return False

    return True


# -----------------------------------------------------------------------------
# XCTest Tests


def generate_linux_tests(linux_tests_generator, tests_dir=None, verbose=False):
    check_linux_tests_generator(linux_tests_generator)
    cmd = [sys.executable, linux_tests_generator, "--tests-dir", tests_dir]
    if verbose:
        cmd.append("--verbose")
    check_call(cmd, verbose=verbose)


def run_xctests(toolchain, build_dir, multiroot_data_file, release, verbose):
    print("** Running XCTests **")
    swiftpm_call = get_swiftpm_invocation(
        toolchain=toolchain,
        action="test",
        build_dir=build_dir,
        multiroot_data_file=multiroot_data_file,
        release=release,
    )

    if verbose:
        swiftpm_call.extend(["--verbose"])

    swiftpm_call.extend(["--test-product", "{}PackageTests".format(PACKAGE_NAME)])

    env = dict(os.environ)
    env["SWIFT_BUILD_SCRIPT_ENVIRONMENT"] = "1"
    # Tell other projects in the unified build to use local dependencies
    env["SWIFTCI_USE_LOCAL_DEPS"] = "1"
    return call(swiftpm_call, env=env, verbose=verbose) == 0


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

    # -------------------------------------------------------------------------

    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Enable verbose logging."
    )

    # -------------------------------------------------------------------------
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

    # -------------------------------------------------------------------------
    build_group = parser.add_argument_group("Build")

    build_group.add_argument(
        "-r", "--release", action="store_true", help="Build in release mode."
    )

    build_group.add_argument(
        "--build-dir",
        default=None,
        help="The directory in which build products shall be put. If omitted "
        'a directory named ".build" will be put in the {} '
        "directory.".format(PACKAGE_DIR.split("/").pop()),
    )

    build_group.add_argument(
        "--add-source-locations",
        action="store_true",
        help="Insert ###sourceLocation comments in generated code for "
        "line-directive.",
    )

    build_group.add_argument(
        "--degyb-only",
        action="store_true",
        help="The script only generates swift files from gyb and skips the "
        "rest of the build",
    )

    build_group.add_argument(
        "--disable-sandbox",
        action="store_true",
        help="Disable sandboxes when building with SwiftPM",
    )

    build_group.add_argument(
        "--multiroot-data-file",
        help="Path to an Xcode workspace to create a unified build of "
        "{} with other projects.".format(PRODUCT_NAME),
    )

    build_group.add_argument(
        "--toolchain",
        default=TOOLCHAIN,
        help="The path to the toolchain that shall be used to build {} (default: %(default)s).".format(
            PRODUCT_NAME
        ),
    )

    # -------------------------------------------------------------------------
    test_group = parser.add_argument_group("Test")

    test_group.add_argument("-t", "--test", action="store_true", help="Run tests")

    test_group.add_argument(
        "--linux-tests-generator",
        default=LINUX_TESTS_GENERATOR,
        help="Path to the Linux tests generator (default: %(default)s).",
    )

    test_group.add_argument(
        "--tests-dir",
        default="Tests",
        help="The path for the tests directory (default: %(default)s).",
    )

    test_group.add_argument(
        "--filecheck-exec",
        default=None,
        help="Path to the FileCheck executable that was built as part of the "
        "LLVM repository. If not specified, it will be looked up from "
        "PATH.",
    )

    test_group.add_argument(
        "--gyb-exec",
        default=GYB_EXEC,
        help="Path to the gyb tool (default: %(default)s).",
    )

    test_group.add_argument(
        "--verify-generated-files",
        action="store_true",
        help="Instead of generating files using gyb, verify that the files "
        "which already exist match the ones that would be generated by "
        "this script.",
    )

    return parser.parse_args()


# -----------------------------------------------------------------------------


def main():
    args = parse_args()

    try:
        if not args.verify_generated_files:
            generate_gyb_files(
                args.gyb_exec,
                verbose=args.verbose,
                add_source_locations=args.add_source_locations,
            )
    except subprocess.CalledProcessError as e:
        printerr("FAIL: Generating .gyb files failed")
        printerr("Executing: %s" % " ".join(e.cmd))
        printerr(e.output)
        sys.exit(1)

    if args.verify_generated_files:
        try:
            success = verify_generated_files(args.gyb_exec, verbose=args.verbose)
        except subprocess.CalledProcessError as e:
            printerr(
                "FAIL: Gyb-generated files committed to repository do "
                "not match generated ones. Please re-generate the "
                "gyb-files and recommit them."
            )
            sys.exit(1)

    # Skip the rest of the build if we should perform degyb only
    if args.degyb_only:
        sys.exit(0)

    if args.generate_xcodeproj:
        generate_xcodeproj(config=args.xcconfig_path)
        sys.exit(0)

    try:
        builder = Builder(
            toolchain=args.toolchain,
            build_dir=args.build_dir,
            multiroot_data_file=args.multiroot_data_file,
            release=args.release,
            verbose=args.verbose,
            disable_sandbox=args.disable_sandbox,
        )
        builder.build(PRODUCT_NAME)

    except subprocess.CalledProcessError as e:
        printerr("FAIL: Building product failed")
        printerr("Executing: %s" % " ".join(e.cmd))
        printerr(e.output)
        sys.exit(1)

    if args.test:
        try:
            generate_linux_tests(
                args.linux_tests_generator, args.tests_dir, verbose=args.verbose
            )
        except subprocess.CalledProcessError as e:
            printerr("FAIL: Generating Linux tests files failed")
            printerr("Executing: %s" % " ".join(e.cmd))
            printerr(e.output)
            sys.exit(1)

        try:
            success = run_tests(
                toolchain=args.toolchain,
                build_dir=realpath(args.build_dir),
                multiroot_data_file=args.multiroot_data_file,
                release=args.release,
                filecheck_exec=realpath(args.filecheck_exec),
                verbose=args.verbose,
            )
            if not success:
                # An error message has already been printed by the failing test
                # suite
                sys.exit(1)
            else:
                print("** All tests passed **")
        except subprocess.CalledProcessError as e:
            printerr("FAIL: Running tests failed")
            printerr("Executing: %s" % " ".join(e.cmd))
            printerr(e.output)
            sys.exit(1)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(1)
