/*
	PureMVC Flex Demo - LoadupForAssets - loading assets with the Loadup utility
	Copyright (c) 2008-09 Philip Sexton <philip.sexton@puremvc.org>
	Your reuse is governed by the Creative Commons Attribution 3.0 License
*/
package org.puremvc.as3.demos.flex.loadupforassets {
	import org.puremvc.as3.interfaces.IFacade;
	import org.puremvc.as3.patterns.facade.Facade;
	import org.puremvc.as3.patterns.observer.Notification;

    import org.puremvc.as3.utilities.loadup.controller.LoadupResourceLoadedCommand;
    import org.puremvc.as3.utilities.loadup.controller.LoadupResourceFailedCommand;

    import org.puremvc.as3.demos.flex.loadupforassets.controller.StartupCommand;
    import org.puremvc.as3.demos.flex.loadupforassets.controller.LoadAssetGroupCommand;

	public class ApplicationFacade extends Facade implements IFacade
	{
		// Notification name constants
		public static const STARTUP :String = "startup";
		public static const LOAD_ASSET_GROUP :String = "loadAssetGroup";

        // Model data, proxy names
		public static const URL_GROUP :String = "urlGroup";
		public static const SINGLE_URLS :String = "singleUrls";

        public static const SINGLE_ASSETS_LU_PROXY_NAME :String = "SingleAssetsLoadupMonitorProxy";
        public static const SINGLE_ASSETS_GROUP_PROXY_NAME :String = "SingleAssetsAssetGroupProxy";

        public static const GROUP_ASSETS_LU_PROXY_NAME :String = "GroupOfAssetsLoadupMonitorProxy";
        public static const GROUP_ASSETS_GROUP_PROXY_NAME :String = "GroupOfAssetsAssetGroupProxy";

		/**
		 * Singleton ApplicationFacade Factory Method
		 */
		public static function getInstance() : ApplicationFacade {
			if ( instance == null ) instance = new ApplicationFacade( );
			return instance as ApplicationFacade;
		}

		/**
		 * Register Commands with the Controller 
		 */
		override protected function initializeController( ) : void {
			super.initializeController();			
			registerCommand( STARTUP, StartupCommand );
			registerCommand( LOAD_ASSET_GROUP, LoadAssetGroupCommand );
			
			// For Loadup Utility...
			// But we don't bother to do this here, because we are using a 
			// LoadAssetGroupCommand and we know that it does this registerCommand.
			//---------------------------------------------------------------------------------
            //registerCommand( Loadup.ASSET_LOADED, LoadupResourceLoadedCommand );
            //registerCommand( Loadup.ASSET_LOAD_FAILED, LoadupResourceFailedCommand );
			//---------------------------------------------------------------------------------
		}

        public function startup(app:Object) :void {
            sendNotification( STARTUP, app );
        }

	}
}