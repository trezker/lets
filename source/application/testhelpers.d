module application.testhelpers;

import std.json;
import boiler.ActionTester;
import application.Database;
import application.storage.user;
import application.CreateUser;
import application.Login;
import application.CreateEvent;
import application.storage.event;
import std.datetime;
import vibe.data.json;


void CreateTestUser(string name, string password) {
	Database database = GetDatabase("test");
	
	CreateUser m = new CreateUser(new User_storage(database));
	JSONValue jsoninput;
	jsoninput["username"] = name;
	jsoninput["password"] = password;

	ActionTester tester = new ActionTester(&m.Perform, jsoninput.toString);

	database.Sync();
}

ActionTester TestLogin(string name, string password) {
	Database database = GetDatabase("test");
	Login login = new Login(new User_storage(database));
	JSONValue jsoninput;
	jsoninput["username"] = name;
	jsoninput["password"] = password;
	ActionTester tester = new ActionTester(&login.Perform, jsoninput.toString);
	return tester;
}


ActionTester CreateTestEvent() {
	CreateTestUser("testname", "testpass");
	auto tester = TestLogin("testname", "testpass");

	Database database = GetDatabase("test");
	CreateEvent m = new CreateEvent(new Event_storage(database));
	Event event = {
		title: "Title",
		description: "Description",
		createdTime: Clock.currTime(),
		startTime: Clock.currTime(),
		endTime: Clock.currTime(),
		location: {
			latitude: 2,
			longitude: 2
		}
	};
	Json jsoninput = serialize!(JsonSerializer, Event)(event);

	tester.Request(&m.Perform, jsoninput.toString);
	return tester;
}