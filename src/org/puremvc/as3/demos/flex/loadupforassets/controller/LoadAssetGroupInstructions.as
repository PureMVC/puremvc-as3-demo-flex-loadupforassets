/*
	PureMVC Flex Demo - LoadupForAssets - loading assets with the Loadup utility
	Copyright (c) 2009 Philip Sexton <philip.sexton@puremvc.org>
	Your reuse is governed by the Creative Commons Attribution 3.0 License
*/
package org.puremvc.as3.demos.flex.loadupforassets.controller
{
    import org.puremvc.as3.utilities.loadup.interfaces.IRetryParameters;

    /**
     *  LoadAssetGroupInstructions, in LoadupForAssets (LFA), defines the instructions required 
     *  by the LFA's LoadAssetGroupCommand, sent to it as the notification body.
     *  For the instructions to be sufficient, there must be a Loadup Monitor ProxyName and an 
     *  assetGroupProxyName and a groupOfUrls.
     */
	public class LoadAssetGroupInstructions {

        private var _luMonitorProxyName :String;
        private var _assetGroupProxyName :String;
        private var _groupOfUrls :Array;
        private var _retryParameters :IRetryParameters;
        private var _progressReportInterval :Number;

		public function LoadAssetGroupInstructions( luMonitorProxyName :String,
		    assetGroupProxyName :String, groupOfUrls :Array,
		    retryParameters :IRetryParameters =null, progressReportInterval :Number =NaN )
		{
            this._luMonitorProxyName = luMonitorProxyName;
		    this._assetGroupProxyName = assetGroupProxyName;
		    this._groupOfUrls = groupOfUrls;
		    this._retryParameters = retryParameters;
		    this._progressReportInterval = progressReportInterval;
		}
		public function get luMonitorProxyName() :String { return _luMonitorProxyName; }
		public function get assetGroupProxyName() :String { return _assetGroupProxyName; }
		public function get groupOfUrls() :Array { return _groupOfUrls; }
		public function get retryParameters() :IRetryParameters { return _retryParameters; }
		public function get progressReportInterval() :Number { return _progressReportInterval; }

		public function isSufficient() :Boolean {
		    if ( luMonitorProxyName != "" && assetGroupProxyName != "" && groupOfUrls.length > 0 )
		        return true;
		    else
		        return false;
		}
	}
}
