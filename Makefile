.PHONY: install clean-build verify-so setup-local-build wheel install-wheel

# Use local disk (/tmp) for ALL build artifacts to avoid 3FS data corruption
NVTE_CMAKE_BUILD_DIR ?= /tmp/te_cmake_build
LOCAL_BUILD_DIR ?= /tmp/te_build
LOCAL_WHEEL_DIR ?= /tmp/te_wheel_dist
WHEEL_DIST_DIR ?= /mnt/3fs/dots-pretrain/jingmai/softwares/TransformerEngine/dist

setup-local-build:
	@echo "[DEBUG] Redirecting build/ -> $(LOCAL_BUILD_DIR) (local disk, avoiding 3FS corruption)"
	@rm -rf build $(LOCAL_BUILD_DIR)
	@mkdir -p $(LOCAL_BUILD_DIR)
	@ln -sf $(LOCAL_BUILD_DIR) build

install: setup-local-build
	NVTE_CMAKE_BUILD_DIR=$(NVTE_CMAKE_BUILD_DIR) NVTE_CUDA_ARCHS="100a" NVTE_BUILD_THREADS_PER_JOB=8 NVTE_FRAMEWORK=pytorch pip install --no-cache-dir --no-build-isolation --no-deps .
	@$(MAKE) verify-so

wheel: setup-local-build
	@echo "[INFO] Building TransformerEngine wheel..."
	@rm -rf $(LOCAL_WHEEL_DIR)
	@mkdir -p $(LOCAL_WHEEL_DIR)
	NVTE_CMAKE_BUILD_DIR=$(NVTE_CMAKE_BUILD_DIR) NVTE_CUDA_ARCHS="100a" NVTE_BUILD_THREADS_PER_JOB=8 NVTE_FRAMEWORK=pytorch pip wheel --no-cache-dir --no-build-isolation --no-deps -w $(LOCAL_WHEEL_DIR) .
	@echo "[INFO] Copying wheel to $(WHEEL_DIST_DIR)..."
	@mkdir -p $(WHEEL_DIST_DIR)
	@cp -f $(LOCAL_WHEEL_DIR)/transformer_engine-*.whl $(WHEEL_DIST_DIR)/
	@echo ""
	@echo "[INFO] Wheel(s) available at $(WHEEL_DIST_DIR):"
	@ls -lh $(WHEEL_DIST_DIR)/transformer_engine-*.whl
	@echo ""
	@echo "[INFO] To install: pip install --no-cache-dir --no-deps --force-reinstall $(WHEEL_DIST_DIR)/transformer_engine-<version>.whl"

install-wheel:
	@echo "[INFO] Installing TransformerEngine from wheel..."
	pip install --no-cache-dir --no-deps --force-reinstall $(WHEEL_DIST_DIR)/transformer_engine-*.whl
	@$(MAKE) verify-so

verify-so:
	@echo "=== Verifying libtransformer_engine.so integrity ==="
	@python3 -c "import os; so='/usr/local/lib/python3.12/dist-packages/transformer_engine/libtransformer_engine.so'; st=os.stat(so); f=open(so,'rb'); data=f.read(); f.close(); ok=len(data)==st.st_size; print(f'Size reported: {st.st_size}, actually read: {len(data)}, OK: {ok}'); assert ok, f'TRUNCATED! {st.st_size} vs {len(data)}'"
	@python3 -c "import transformer_engine; print(f'transformer_engine {transformer_engine.__version__} loaded OK')"

clean-build:
	rm -rf /tmp/te_cmake_build /tmp/te_build /tmp/te_wheel_dist build dist *.egg-info
