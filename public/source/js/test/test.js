var TestSuite = function() {
	var self = this;
	self.iFrameDOM = $("iframe#test").contents();

	self.alert = function() {
		setTimeout(function(){
			$(self.iFrameDOM.find("input")[0]).sendkeys("a");
			$(self.iFrameDOM.find("input")[1]).sendkeys("a");
			setTimeout(function(){
				$(self.iFrameDOM.find("button")[1]).click();
			}, 1000);
		}, 1000);
	}
};

function iframeLoaded() {
	var suite = new TestSuite();
	suite.alert();
}

$("#test").attr("src", "/");
