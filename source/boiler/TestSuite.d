module boiler.testsuite;

alias Test = void delegate();
class TestSuite {
	private Test[] tests;

	void Setup() {}
	void Teardown() {}

	void Run() {
		foreach (test; tests) {
			Setup();
			test();
			Teardown();
		}
	}

	void AddTest(Test test) {
		tests ~= test;
	}
}
