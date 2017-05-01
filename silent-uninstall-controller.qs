function Controller() {
    installer.autoRejectMessageBoxes();
    installer.uninstallationFinished.connect(function() {
        gui.clickButton(buttons.FinishButton);
    })
}

Controller.prototype.IntroductionPageCallback = function() {
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.ReadyForInstallationPageCallback = function(){
    gui.clickButton(buttons.NextButton);
}



