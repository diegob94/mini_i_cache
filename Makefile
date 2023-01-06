WITH_VENV = . .venv/bin/activate &&

.PHONY: run
run: .venv
	$(WITH_VENV) svutRun -sim icarus -f files.f -test mini_i_cache_testbench.sv

.PHONY: clean
clean:
	rm -fv svut_h.sv svut.out mini_i_cache_testbench.vcd

.PHONY: lint
lint:
	verilator -sv -lint-only mini_i_cache_testbench.sv

.venv:
	python -m venv .venv
	$(WITH_VENV) pip install --upgrade pip
	$(WITH_VENV) pip install svut

