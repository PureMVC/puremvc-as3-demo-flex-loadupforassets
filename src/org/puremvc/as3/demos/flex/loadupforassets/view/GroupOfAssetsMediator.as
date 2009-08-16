/*
	PureMVC Flex Demo - LoadupForAssets - loading assets with the Loadup utility
	Copyright (c) 2008 Philip Sexton <philip.sexton@puremvc.org>
	Your reuse is governed by the Creative Commons Attribution 3.0 License
*/
package org.puremvc.as3.demos.flex.loadupforassets.view {
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ListCollectionView;
	import mx.controls.Button;
	import mx.controls.ProgressBar;
	import mx.controls.ProgressBarMode;
	import mx.core.UIComponent;
	
	import org.puremvc.as3.demos.flex.loadupforassets.ApplicationFacade;
	import org.puremvc.as3.interfaces.IMediator;
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.mediator.Mediator;
	import org.puremvc.as3.patterns.proxy.Proxy;
	import org.puremvc.as3.utilities.loadup.Loadup;
	import org.puremvc.as3.utilities.loadup.model.LoadupMonitorProxy;
	import org.puremvc.as3.utilities.loadup.assetloader.interfaces.IAsset;
	import org.puremvc.as3.utilities.loadup.assetloader.interfaces.IAssetForFlex;
	import org.puremvc.as3.utilities.loadup.assetloader.model.AssetProxy;
	import org.puremvc.as3.utilities.loadup.assetloader.model.AssetGroupProxy;
	import org.puremvc.as3.utilities.loadup.model.RetryParameters;

    import org.puremvc.as3.demos.flex.loadupforassets.view.components.GroupOfAssets;
    import org.puremvc.as3.demos.flex.loadupforassets.controller.LoadAssetGroupInstructions;

	public class GroupOfAssetsMediator extends Mediator implements IMediator
	{
		public static const NAME:String = "GroupOfAssetsMediator";

        private var progressMessages :ListCollectionView = new ArrayCollection();
        private var groupOfUrls :Array;

        private var loadBtn :Button = new Button();
        private var loadProgressBar :ProgressBar = new ProgressBar();

		public function GroupOfAssetsMediator( viewComponent:Object ) {
			super( NAME, viewComponent );
		}
		override public function onRegister() :void {
			groupOfAssets.progressMessages = progressMessages;

            loadBtn.label = "Load Assets";
            loadBtn.addEventListener( MouseEvent.CLICK, onLoad );
            controlsDisplayComponent.addChild( loadBtn );

            loadProgressBar.mode = ProgressBarMode.MANUAL;
		}
		
		protected function get groupOfAssets() :GroupOfAssets {
			return viewComponent as GroupOfAssets;
		}
		protected function get assetsDisplayComponent() :UIComponent {
			return groupOfAssets.assetsDisplayComponent as UIComponent;
		}
		protected function get controlsDisplayComponent() :UIComponent {
			return groupOfAssets.controlsDisplayComponent as UIComponent;
		}

        private function onLoad( event:Event ) :void {
            loadBtn.enabled = false;
            loadBtn.removeEventListener( MouseEvent.CLICK, onLoad );
	        controlsDisplayComponent.removeChild( loadBtn );

            controlsDisplayComponent.addChild( loadProgressBar );
            sendNotification( ApplicationFacade.LOAD_ASSET_GROUP, loadingInstructions() );
        }

        /**
         *  We choose to ignore the following notifications:<ul>
         *  <li>Loadup.LOADING_PROGRESS</li>
         *  <li>Loadup.LOAD_RESOURCE_TIMED_OUT</li>
         *  <li>Loadup.WAITING_FOR_MORE_RESOURCES</li>
         *  </ul>
         */
		override public function listNotificationInterests():Array {
			return [
			    Loadup.LOADING_COMPLETE,
			    Loadup.LOADING_FINISHED_INCOMPLETE,
			    Loadup.CALL_OUT_OF_SYNC_IGNORED,

			    Loadup.RETRYING_LOAD_RESOURCE,

				//Loadup.ASSET_LOAD_FAILED,
				Loadup.ASSET_LOAD_FAILED_IOERROR,
				Loadup.ASSET_LOAD_FAILED_SECURITY,
				Loadup.NEW_ASSET_AVAILABLE,
				Loadup.ASSET_GROUP_LOAD_PROGRESS,
                Loadup.URL_REFUSED_PROXY_NAME_ALREADY_EXISTS
                ];
		}

        /**
         *  All the notifications to be handled, whether from Loadup Monitor or
         *  AssetGroupProxy, are of interest only if the notification type matches
         *  the Proxy Name for the Loadup Monitor instance handling this group
         *  of assets.
         */
		override public function handleNotification( note:INotification ):void {
		    if ( note.getType() == ApplicationFacade.GROUP_ASSETS_LU_PROXY_NAME )
		        doHandleNotification( note );
		}
		
		private function doHandleNotification( note:INotification ):void {
		    var errMsg :String;
			switch ( note.getName() ) {
			    /*case Loadup.ASSET_LOAD_FAILED:
		            progressMessages.addItemAt( "Asset Load Failed", 0);
			        break;*/

			    case Loadup.ASSET_LOAD_FAILED_IOERROR:
			    case Loadup.ASSET_LOAD_FAILED_SECURITY:
	                var assetPx :AssetProxy = note.getBody() as AssetProxy;
	                errMsg = (note.getBody() as AssetProxy).getLoadingErrorMessage();
		            progressMessages.addItemAt( "Asset Load Failed, Asset=" + assetPx.url, 0);
		            progressMessages.addItemAt( "...Msg=" + errMsg, 1);
		            var textPart :Array = errMsg.match( /text=.*?\Z/ );
		            if ( textPart )
    		            progressMessages.addItemAt( "..." + textPart[0], 2);
			        break;

			    case Loadup.ASSET_GROUP_LOAD_PROGRESS:
                    progressMessages.addItemAt( "Progress, %=" + (note.getBody() as Number).toString(), 0);
		            loadProgressBar.setProgress( note.getBody() as Number, 100);
			        break;

			    case Loadup.NEW_ASSET_AVAILABLE:
		            var child :UIComponent = (note.getBody() as IAssetForFlex).uiComponent;
		            child.width = 120;
		            child.height = 120;
		            assetsDisplayComponent.addChild( child );
                    progressMessages.addItemAt( "Displayed new asset: " + ( note.getBody() as IAsset).url, 0);
			        break;

			    case Loadup.URL_REFUSED_PROXY_NAME_ALREADY_EXISTS:
		            progressMessages.addItemAt( 
		                "Asset Url Refused, Proxy Name Already Exists, url=" + note.getBody() as String, 0 );
			        break;

			    case Loadup.RETRYING_LOAD_RESOURCE:
		            progressMessages.addItemAt( "Retrying", 0);
			        break;

			    case Loadup.LOADING_COMPLETE:
			        controlsDisplayComponent.removeChild( loadProgressBar );
			        progressMessages.addItemAt( "Loading Complete, This Group Of Assets All Loaded", 0);
			        removeGroupOfAssetsLoadEnv();
			        break;

			    case Loadup.LOADING_FINISHED_INCOMPLETE:
		            progressMessages.addItemAt( "Loading Finished BUT INCOMPLETE", 0);
		            removeGroupOfAssetsLoadEnv();
			        break;

			    case Loadup.CALL_OUT_OF_SYNC_IGNORED:
		            progressMessages.addItemAt( "LU ignores Call Out Of Sync", 0);
		            // we choose to throw Error
		            throw Error( "LU reports Call Out Of Sync; please debug" );
			        break;
			}
		}

        /**
         *  The loading instructions must include LU monitor proxy name and asset group proxy name 
         *  and groupOfUrls.  We also want to specify the retry parameters and the progress reporting 
         *  interval that we want the LU to use.
         *  <p>
         *  The retry parameters are: maxRetries, retryInterval in secs, timeout in secs
         *  <ul>
         *  <li>they apply per asset</li>
         *  <li>the LoadupAsOrdered demo offers option to play with these parameters.</li></ul>
         *  </p><p>
         *  Override Loadup's standard progress report interval ( it applies to asset loading )
         *  - a small interval, say 5 msecs, is better for this demo.
         *  </p>
         */
         private function loadingInstructions() :LoadAssetGroupInstructions {
			// named Proxy registered in StartupCommand
			var groupOfUrls:Array = Proxy(facade.retrieveProxy(ApplicationFacade.URL_GROUP)).getData() as Array;

			// maxRetries 2, retryInterval 10 secs, timeout 300 secs
			var retryParams:RetryParameters = new RetryParameters( 2, 10, 300 );

			// progressReportInterval .005 secs i.e. 5 msecs.
			var progressReportInterval:Number = .005;

			var instructions:LoadAssetGroupInstructions = new LoadAssetGroupInstructions(
			    ApplicationFacade.GROUP_ASSETS_LU_PROXY_NAME,
			    ApplicationFacade.GROUP_ASSETS_GROUP_PROXY_NAME,
                groupOfUrls,
                retryParams,
                progressReportInterval
            );
            return instructions;
         }

         /**
          *  This could be a Command.
          */
         private function removeGroupOfAssetsLoadEnv() :void {
             var luMon :LoadupMonitorProxy = facade.removeProxy( 
                 ApplicationFacade.GROUP_ASSETS_LU_PROXY_NAME ) as LoadupMonitorProxy;
             if ( luMon ) luMon.cleanup();

             var groupPx :AssetGroupProxy = facade.retrieveProxy(
                 ApplicationFacade.GROUP_ASSETS_GROUP_PROXY_NAME) as AssetGroupProxy;
             if ( groupPx ) groupPx.cleanupAfterLoading();

             // And remove asset group proxy and asset proxies, if desired;
             // you would not do this if you want to retain the asset group and assets
             // for further read-only use.
             if ( groupPx ) groupPx.cleanup();
         }

	}
}