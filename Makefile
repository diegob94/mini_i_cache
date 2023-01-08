WITH_VENV = . .venv/bin/activate &&
NO_COLOR = sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g'
PYTHON_LINE_BUFFERING = stdbuf -oL -eL

.PHONY: run
run: .venv
	$(WITH_VENV) $(PYTHON_LINE_BUFFERING) svutRun -sim icarus -f files.f -test mini_i_cache_testbench.sv 2>&1 | tee -i svut.log

.PHONY: log
log:
	$(NO_COLOR) -i svut.log

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

