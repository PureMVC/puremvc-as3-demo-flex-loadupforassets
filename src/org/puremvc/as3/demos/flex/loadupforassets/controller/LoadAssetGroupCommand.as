/*
	PureMVC Flex Demo - LoadupForAssets - loading assets with the Loadup utility
	Copyright (c) 2009 Philip Sexton <philip.sexton@puremvc.org>
	Your reuse is governed by the Creative Commons Attribution 3.0 License
*/
package org.puremvc.as3.demos.flex.loadupforassets.controller {
	
	import org.puremvc.as3.interfaces.ICommand;
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.interfaces.IProxy;
	import org.puremvc.as3.patterns.command.SimpleCommand;

	import org.puremvc.as3.utilities.loadup.Loadup;
	import org.puremvc.as3.utilities.loadup.model.LoadupMonitorProxy;
	import org.puremvc.as3.utilities.loadup.model.RetryPolicy;
	import org.puremvc.as3.utilities.loadup.interfaces.ILoadupProxy;
	import org.puremvc.as3.utilities.loadup.controller.LoadupResourceLoadedCommand;
	import org.puremvc.as3.utilities.loadup.controller.LoadupResourceFailedCommand;

    import org.puremvc.as3.utilities.loadup.assetloader.model.AssetGroupProxy;
    import org.puremvc.as3.utilities.loadup.assetloader.model.AssetProxy;
    import org.puremvc.as3.utilities.loadup.assetloader.model.AssetTypeMap;
    import org.puremvc.as3.utilities.loadup.assetloader.model.AssetFactory;
    import org.puremvc.as3.utilities.loadup.assetloader.model.AssetLoaderFactory;
    import org.puremvc.as3.utilities.loadup.assetloader.interfaces.IAsset;
    import org.puremvc.as3.utilities.loadup.assetloader.interfaces.IAssetTypeMap;
    import org.puremvc.as3.utilities.loadup.assetloader.interfaces.IAssetFactory;
    import org.puremvc.as3.utilities.loadup.assetloader.interfaces.IAssetLoaderFactory;

    /**
     *  We choose to load this group of assets using a new AssetGroupProxy and a new 
     *  LoadupMonitorProxy, dedicated just to this group of assets.
     *  <p>
     *  Notification body is the loading instructions; it must be a LoadAssetGroupInstructions object.
     *  Instructions must include the two proxy names and the group of urls as an array of url strings.
     *  Instructions can also include a specification of retry parameters, if the Loadup default is to
     *  be overriden - see LoadupMonitorProxy. The retry parameters apply per asset.  The instructions
     *  can also specify a loading progress interval, to dictate the frequency of progress reporting, 
     *  if the default is to be overriden - see AssetGroupProxy.</p>
     *  <p>
     *  As regards retry parameters, note that the LoadupAsOrdered demo offers interactive
     *  experience with them.</p>
     *  <p>
     *  We register each asset with the Loadup utility (LU) using addResourceViaLoadupProxy()
     *  - this is a nice shortcut but it requires that the LU will create the corresponding 
     *  LoadupResourceProxy object internally and assumes that we don't need access to that 
     *  object, or at least we don't need easy access to it i.e. we don't have a local reference
     *  to it and we haven't specified its proxy name.</p>
     */
	public class LoadAssetGroupCommand extends SimpleCommand implements ICommand {

		protected const INSTRUCTIONS_NOT_SUFFICIENT_MSG :String =
		    "LoadAssetGroupCommand, instructions are not sufficient, cannot proceed";
		protected const PROXY_NAME_EXISTS_MSG :String =
            "LoadAssetGroupCommand, proxy name already exists, cannot proceed, name=";

		private var loadupMon :LoadupMonitorProxy;

        override public function execute( note :INotification ) : void {

            var instructions :LoadAssetGroupInstructions = note.getBody() as LoadAssetGroupInstructions;
            if ( ! instructions.isSufficient() )
                throw new Error( INSTRUCTIONS_NOT_SUFFICIENT_MSG );

            // we will use a new AssetGroupProxy and a new LoadupMonitorProxy,
            // dedicated just to this group of assets.

            if ( facade.hasProxy( instructions.assetGroupProxyName ))
                throw new Error( PROXY_NAME_EXISTS_MSG + instructions.assetGroupProxyName );

            if ( facade.hasProxy( instructions.luMonitorProxyName ))
                throw new Error( PROXY_NAME_EXISTS_MSG + instructions.luMonitorProxyName );

            this.loadupMon = new LoadupMonitorProxy( instructions.luMonitorProxyName );

            facade.registerProxy( loadupMon );

            prepAssetGroupForLoad( instructions );
            startLoading();
        }

        protected function prepAssetGroupForLoad( instructions :LoadAssetGroupInstructions ) :void {

            // Make sure these 2 commands are registered for asset loading, 
            // even if it has already been done.
            facade.registerCommand( Loadup.ASSET_LOADED, LoadupResourceLoadedCommand );
            facade.registerCommand( Loadup.ASSET_LOAD_FAILED, LoadupResourceFailedCommand );

            var assetGroupProxyName :String = instructions.assetGroupProxyName;
            var groupOfUrls :Array = instructions.groupOfUrls;

            var assetTypeMap :IAssetTypeMap = new AssetTypeMap();
            var assetFactory :IAssetFactory = new AssetFactory( assetTypeMap );
            var assetLoaderFactory :IAssetLoaderFactory = new AssetLoaderFactory( assetTypeMap );

            var groupPx :AssetGroupProxy = new AssetGroupProxy( assetLoaderFactory, 
                assetGroupProxyName, loadupMon );
            facade.registerProxy( groupPx );

            // possibly override default progress report interval
            if ( instructions.progressReportInterval )
                groupPx.progressReportInterval = instructions.progressReportInterval;

            // possibly override default LU retry policy
            if ( instructions.retryParameters )
                loadupMon.defaultRetryPolicy = new RetryPolicy( instructions.retryParameters );

            // create an asset for each url and an asset proxy for each asset,
            // we use the url for the proxy name.
            for ( var i:int=0; i < groupOfUrls.length; i++ ) {
                var url :String = groupOfUrls[i];
                if ( facade.hasProxy( url )) {
                    sendNotification( Loadup.URL_REFUSED_PROXY_NAME_ALREADY_EXISTS, url, 
                        loadupMon.getProxyName() );
                }
                else {
                    var asset :IAsset = assetFactory.getAsset( url );
                    var px :IProxy = new AssetProxy( groupPx, url, asset );
                    facade.registerProxy( px );
                    groupPx.addAssetProxy ( px );
                    loadupMon.addResourceViaLoadupProxy( px as ILoadupProxy );
                }
            }

        }
        protected function startLoading() :void {
            loadupMon.loadResources();
        }

	}	
}
