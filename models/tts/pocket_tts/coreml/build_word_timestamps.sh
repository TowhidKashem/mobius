#!/usr/bin/env bash
set -euo pipefail

LANGUAGE="${LANGUAGE:-english_2026-10}"
HEADS="${HEADS:-L3H8+L2H0}"
POCKET_TTS_REF="${POCKET_TTS_REF:-c91f50f}"

cd "$(dirname "$0")/.."

if [ ! -d pocket_tts ]; then
  upstream="$(mktemp -d)"
  git clone https://github.com/kyutai-labs/pocket-tts.git "$upstream"
  git -C "$upstream" checkout "$POCKET_TTS_REF"
  cp -r "$upstream/pocket_tts" ./pocket_tts
  rm -rf "$upstream"
fi

uv sync --extra coreml

uv run python coreml/convert_models/convert/convert_flowlm_step.py \
  --language "$LANGUAGE" \
  --attention-heads "$HEADS"

build_dir="coreml/build/$LANGUAGE"
rm -rf "$build_dir/flowlm_step.mlmodelc"
uv run python -c "import coremltools as ct, sys; ct.utils.compile_model(sys.argv[1], sys.argv[2])" \
  "$build_dir/flowlm_step.mlpackage" "$build_dir/flowlm_step.mlmodelc"

echo "Built $build_dir/flowlm_step.mlmodelc"
