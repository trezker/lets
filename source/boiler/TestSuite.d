module boiler.testsuite;

alias Test = void delegate();
class TestSuite {
	private Test[] tests;

	void Setup() {}
	void Teardown() {}

	void Run() {
		foreach (test; tests) {
			try {
				Setup();
				test();
			}
			finally {
				Teardown();
			}
		}
	}

	void AddTest(Test test) {
		tests ~= test;
	}
}
