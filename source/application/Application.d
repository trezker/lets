module application.Application;

import vibe.http.server;
import vibe.core.log;

import mondo;
import boiler.Ajax;
import boiler.HttpRequest;

import application.Database;
import application.storage.user;
import application.CreateUser;
import application.Login;
import application.Logout;
import application.CurrentUser;

import application.storage.event;
import application.CreateEvent;
import application.UpdateEvent;
import application.DeleteEvent;
import application.EventsInArea;
import application.MyEvents;

class Application {
	void SetupAjaxMethods(Ajax ajax) {
		Database database = GetDatabase(null);
		auto userStorage = new User_storage(database);

		ajax.SetActionCreator("CreateUser", () => new CreateUser(userStorage));
		ajax.SetActionCreator("Login", () => new Login(userStorage));
		ajax.SetActionCreator("Logout", () => new Logout);
		ajax.SetActionCreator("CurrentUser", () => new CurrentUser(userStorage));

		auto eventStorage = new Event_storage(database);
		ajax.SetActionCreator("CreateEvent", () => new CreateEvent(eventStorage));
		ajax.SetActionCreator("UpdateEvent", () => new UpdateEvent(eventStorage));
		ajax.SetActionCreator("DeleteEvent", () => new DeleteEvent(eventStorage));
		ajax.SetActionCreator("EventsInArea", () => new EventsInArea(eventStorage));
		ajax.SetActionCreator("MyEvents", () => new MyEvents(eventStorage));
	}

	string RewritePath(HttpRequest request) {
		if(!request.session) {
			return "/login";
		}
		return request.path;
	}
}
