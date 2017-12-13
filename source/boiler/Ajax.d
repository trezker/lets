module boiler.Ajax;

import std.stdio;
import vibe.http.server;
import vibe.data.json;

import boiler.ActionTester;
import boiler.HttpRequest;
import boiler.HttpResponse;
import boiler.helpers;
import boiler.testsuite;

alias ActionCreator = Action delegate();

class Ajax: Action {
	private ActionCreator[string] actionCreators;

	public void SetActionCreator(string name, ActionCreator actionCreator) {
		actionCreators[name] = actionCreator;
	}

	public HttpResponse Perform(HttpRequest req) {
		HttpResponse res;
		try {
			string actionName = req.json["action"].to!string;
			if(actionName in actionCreators) {
				Action action = actionCreators[actionName]();
				res = action.Perform (req);
			}
			else {
				res = new HttpResponse;
				Json json = Json.emptyObject;
				json["success"] = false;
				res.writeBody(serializeToJsonString(json), 200);
			}
		}
		catch(Exception e) {
			Json json = Json.emptyObject;
			json["success"] = false;
			res = new HttpResponse;
			res.writeBody(serializeToJsonString(json), 200);
		}
		return res;
	}
}

class SuccessTestHandler : Action {
	public HttpResponse Perform(HttpRequest req) {
		HttpResponse res = new HttpResponse;
		Json json = Json.emptyObject;
		json["success"] = true;
		res.writeBody(serializeToJsonString(json), 200);
		return res;
	}
}

//Call without parameters should fail.
unittest {
	Ajax ajax = new Ajax();

	ActionTester tester = new ActionTester(&ajax.Perform);

	Json jsonoutput = tester.GetResponseJson();
	assertEqual(jsonoutput["success"].to!bool, false);
}

//Call to method that doesn't exist should fail.
unittest {
	Ajax ajax = new Ajax();

	ActionTester tester = new ActionTester(&ajax.Perform, "{\"action\": \"none\"}");

	Json jsonoutput = tester.GetResponseJson();
	assertEqual(jsonoutput["success"].to!bool, false);
}

//Call to method that exists should succeed.
unittest {
	Ajax ajax = new Ajax();
	ajax.SetActionCreator("test", () => new SuccessTestHandler);

	ActionTester tester = new ActionTester(&ajax.Perform, "{\"action\": \"test\"}");

	Json jsonoutput = tester.GetResponseJson();
	assertEqual(jsonoutput["success"].to!bool, true);
}
