# typed: false
# frozen_string_literal: true

# Homebrew formula for NorthCel — the `.ncel` drawing language CLI with the
# native MoonBit + Bend/HVM2 + GLSL runtime.
#
# This formula lives in the public tap:
#
#   brew tap syver777/northcel
#   brew install northcel          # or: brew install syver777/northcel/northcel
#
# `northcel` is the single install name; `ncel` is the short command alias the
# package itself installs. Nothing is compiled here and nothing is downloaded on
# first run: five sha256-pinned wheels go into a private venv.
class Northcel < Formula
  include Language::Python::Virtualenv

  desc "Drawing language CLI for AI-drawn video, with a native MoonBit + Bend + GLSL runtime"
  homepage "https://northnoir.com/northcel"
  url "https://files.pythonhosted.org/packages/59/a9/8f1be6743916c73d7af84974264452975884eb4df15c2af86dc728df4dcc/northcel-0.2.1.tar.gz"
  sha256 "b9c5ff520e3926936242b7b34d2c9bc50983a2c469e0dfc75820686aeb08f66d"
  license any_of: ["MIT", "Apache-2.0"]

  depends_on :linux
  depends_on arch: :x86_64
  depends_on "mesa" # libEGL + llvmpipe: the GL driver that compiles the GLSL
  depends_on "python@3.12" # the pinned wheels are cp312

  # numpy and Pillow are required by the Python reference renderer, which is also
  # the conformance oracle and the only formatter (`northcel fmt`, `--no-native`).
  resource "numpy" do
    url "https://files.pythonhosted.org/packages/43/a3/c799c62e19c337e6d3770b08e475887fb30ce8477d3c09efca6b2f0228a6/numpy-2.5.4-cp312-cp312-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl"
    sha256 "fbde6962867ee75b48b0ee29b2b9372ec5d617799dbaf38e82dc0596f2f7738a"
  end

  resource "pillow" do
    url "https://files.pythonhosted.org/packages/e6/99/fdf65cc539e266ab93546c261bdf98411fe165c6e4e13f9dbf597097192b/pillow-13.0.0-cp312-cp312-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl"
    sha256 "42d63be3af4f9b951b199b0a9d23365d37ab14687e6d77b74940432c8515c4ca"
  end

  # The Python reference parser/validator/formatter. It installs `northcel` and
  # `ncel` scripts of its own; `ncel` is overwritten below by the launcher, which
  # is a superset (it adds doctor/verify/guide/toolchain and native dispatch).
  resource "northcel" do
    url "https://files.pythonhosted.org/packages/81/40/d069656e05b755f930f5a2a38210bba4626de779d5467f72b1e30acccb59/northcel-0.2.1-py3-none-any.whl"
    sha256 "d24a8ee793bcc0cbe5637b40686c8237833e115cf1f5ebfaca0990f81aa61472"
  end

  # The native bundle: MoonBit-compiled typed AST stage, Bend 0.2.38, HVM 2.0.22,
  # the EGL surfaceless GL host and both GLSL shaders. manylinux_2_39 => glibc 2.39.
  resource "ncel-native" do
    url "https://files.pythonhosted.org/packages/ee/a3/c77c60acb74a125486cc7710d66de189dc8f655156038bba5e0c6dc39b7c/ncel_native-0.2.1-py3-none-manylinux_2_39_x86_64.whl"
    sha256 "0b5f6f74ee41ed904e5c7e8b83f168c2bcf922b3ea7da2792c3babff7f88d06e"
  end

  # The launcher: platform verdict, native dispatch, labelled Python fallback,
  # doctor/verify/check/info/render/film/fmt/guide/toolchain.
  resource "ncel" do
    url "https://files.pythonhosted.org/packages/75/fd/3dd3fe02ebd500cc7f05665542a3fbc7511484357ff075d554d5695a01ab/ncel-0.2.1-py3-none-any.whl"
    sha256 "85f5a73cd0745085a182731d8ff23e83a033c3a670fdecd319181cd57c8b46a1"
  end

  def install
    # Install order matters: Homebrew pip runs with --no-deps, and the launcher
    # must be last so its `ncel` script wins over the reference package's one.
    venv = virtualenv_create(libexec, "python3.12")
    %w[numpy pillow northcel ncel-native ncel].each do |name|
      venv.pip_install resource(name)
    end

    # One install name: `northcel`. `ncel` stays as the package's short alias.
    bin.install_symlink libexec/"bin/ncel" => "northcel"
    bin.install_symlink libexec/"bin/ncel" => "ncel"
  end

  def caveats
    <<~EOS
      NorthCel renders natively on Linux x86_64 with glibc >= 2.39, using Mesa's
      EGL/llvmpipe driver (installed as a dependency) — no GPU is required.

      Prove the installation, then render something:

        northcel doctor          # MoonBit, Bend/HVM2, GLSL and exact versions
        northcel verify          # conformance frame + 6-frame film, rendered twice
        northcel guide           # offline authoring guide

      `ncel` is the same command. `northcel --no-native` (and `northcel fmt`) use
      the bundled Python reference implementation, which labels its output as
      non-native. macOS and Windows are not supported by this formula.
    EOS
  end

  test do
    assert_match "0.2.1", shell_output("#{bin}/northcel version")
    assert_match "\"ok\": true", shell_output("#{bin}/northcel doctor --json")
    system bin/"northcel", "verify"
  end
end
