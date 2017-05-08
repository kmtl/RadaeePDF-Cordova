//  RadaeePDFPlugin
//  GEAR.it s.r.l., http://www.gear.it, http://www.radaeepdf.com
//  Created by Nermeen Solaiman on 06/06/16.

// modified by Nermeen Solaiman on 09/11/16
//      added getFileState prototype
//  v1.1.0

// modified by Nermeen Solaiman/Emanuele on 31/01/17
//      added config prototypes
//  v1.2.0

// modified by Nermeen Solaiman on 26/04/17
//      added getPageCount, extractTextFromPage and encryptDocAs prototypes
//  v1.3.0

var argscheck = require('cordova/argscheck'),
    exec      = require('cordova/exec');

function RadaeePDFPlugin () {};

RadaeePDFPlugin.prototype.activateLicense = function(params, successCallback, errorCallback) {
        params = params || {};
                exec(successCallback, errorCallback, 'RadaeePDFPlugin', 'activateLicense', [params]);
};

RadaeePDFPlugin.prototype.open = function (params, success, failure) {
        argscheck.checkArgs('*fF', 'RadaeePDFPlugin.show', arguments);

        params = params || {};

        exec(success, failure, 'RadaeePDFPlugin', 'show', [params]);
};

RadaeePDFPlugin.prototype.openFromAssets = function(params, successCallback, errorCallback) {
        params = params || {};
                exec(successCallback, errorCallback, 'RadaeePDFPlugin', 'openFromAssets', [params]);
};

RadaeePDFPlugin.prototype.getFileState = function (params, successCallback, errorCallback) {
        params = params || {};

        exec(successCallback, errorCallback, 'RadaeePDFPlugin', 'fileState', [params]);
};

RadaeePDFPlugin.prototype.getPageNumber = function (params, successCallback, errorCallback) {
        params = params || {};

        exec(successCallback, errorCallback, 'RadaeePDFPlugin', 'getPageNumber', [params]);
};

RadaeePDFPlugin.prototype.getJSONFormFields = function (params, successCallback, errorCallback) {
        params = params || {};

        exec(successCallback, errorCallback, 'RadaeePDFPlugin', 'JSONFormFields', [params]);
};

RadaeePDFPlugin.prototype.getJSONFormFieldsAtPage = function (params, successCallback, errorCallback) {
        params = params || {};

        exec(successCallback, errorCallback, 'RadaeePDFPlugin', 'JSONFormFieldsAtPage', [params]);
};

RadaeePDFPlugin.prototype.setFormFieldWithJSON = function (params, successCallback, errorCallback) {
        params = params || {};

        exec(successCallback, errorCallback, 'RadaeePDFPlugin', 'setFormFieldWithJSON', [params]);
};

RadaeePDFPlugin.prototype.setThumbnailBGColor = function (params, successCallback, errorCallback) {
        params = params || {};

        exec(successCallback, errorCallback, 'RadaeePDFPlugin', 'setThumbnailBGColor', [params]);
};

RadaeePDFPlugin.prototype.setReaderBGColor = function (params, successCallback, errorCallback) {
        params = params || {};

        exec(successCallback, errorCallback, 'RadaeePDFPlugin', 'setReaderBGColor', [params]);
};

RadaeePDFPlugin.prototype.setThumbHeight = function (params, successCallback, errorCallback) {
        params = params || {};

        exec(successCallback, errorCallback, 'RadaeePDFPlugin', 'setThumbHeight', [params]);
};

RadaeePDFPlugin.prototype.setFirstPageCover = function (params, successCallback, errorCallback) {
        params = params || {};

        exec(successCallback, errorCallback, 'RadaeePDFPlugin', 'setFirstPageCover', [params]);
};

RadaeePDFPlugin.prototype.setReaderViewMode = function (params, successCallback, errorCallback) {
        params = params || {};

        exec(successCallback, errorCallback, 'RadaeePDFPlugin', 'setReaderViewMode', [params]);
};

RadaeePDFPlugin.prototype.setIconsBGColor = function (params, successCallback, errorCallback) { //android only
        params = params || {};

        exec(successCallback, errorCallback, 'RadaeePDFPlugin', 'setIconsBGColor', [params]);
};

RadaeePDFPlugin.prototype.setTitleBGColor = function (params, successCallback, errorCallback) { //android only
        params = params || {};

        exec(successCallback, errorCallback, 'RadaeePDFPlugin', 'setTitleBGColor', [params]);
};

RadaeePDFPlugin.prototype.setToolbarEnabled = function(params, successCallback, errorCallback) { //iOS only

        params = params || {};

        exec(successCallback, errorCallback, 'RadaeePDFPlugin', 'setToolbarEnabled', [params]);
}

RadaeePDFPlugin.prototype.getPageCount = function (params, successCallback, errorCallback) {
        params = params || {};

        exec(successCallback, errorCallback, 'RadaeePDFPlugin', 'getPageCount', [params]);
};

RadaeePDFPlugin.prototype.extractTextFromPage = function (params, successCallback, errorCallback) {
        params = params || {};

        exec(successCallback, errorCallback, 'RadaeePDFPlugin', 'extractTextFromPage', [params]);
};

RadaeePDFPlugin.prototype.encryptDocAs = function (params, successCallback, errorCallback) {
        params = params || {};

        exec(successCallback, errorCallback, 'RadaeePDFPlugin', 'encryptDocAs', [params]);
};

module.exports = new RadaeePDFPlugin();
