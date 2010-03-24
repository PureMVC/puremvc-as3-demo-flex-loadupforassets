/*
	PureMVC Flex Demo - LoadupForAssets - loading assets with the Loadup utility
	Copyright (c) 2008 Philip Sexton <philip.sexton@puremvc.org>
	Your reuse is governed by the Creative Commons Attribution 3.0 License
*/
package org.puremvc.as3.demos.flex.loadupforassets.view {
	import flash.events.Event;
	import flash.display.Bitmap;
	import flash.display.DisplayObjectContainer;

	import mx.collections.ArrayCollection;
	import mx.collections.ListCollectionView;
	import mx.controls.Alert;
	import mx.controls.Image;
	import mx.core.UIComponent;
	import mx.events.ItemClickEvent;
	
	import org.puremvc.as3.demos.flex.loadupforassets.ApplicationFacade;
	import org.puremvc.as3.interfaces.IMediator;
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.interfaces.IProxy;
	import org.puremvc.as3.patterns.mediator.Mediator;
	import org.puremvc.as3.patterns.proxy.Proxy;

	import org.puremvc.as3.utilities.loadup.Loadup;
	import org.puremvc.as3.utilities.loadup.model.LoadupMonitorProxy;
	import org.puremvc.as3.utilities.loadup.model.RetryParameters;
	import org.puremvc.as3.utilities.loadup.model.RetryPolicy;
	import org.puremvc.as3.utilities.loadup.interfaces.ILoadupProxy;
	import org.puremvc.as3.utilities.loadup.controller.LoadupResourceLoadedCommand;
	import org.puremvc.as3.utilities.loadup.controller.LoadupResourceFailedCommand;

    import org.puremvc.as3.utilities.loadup.assetloader.model.AssetGroupProxy;
    import org.puremvc.as3.utilities.loadup.assetloader.model.AssetProxy;
    import org.puremvc.as3.utilities.loadup.assetloader.model.FlexAssetTypeMap;
    import org.puremvc.as3.utilities.loadup.assetloader.model.AssetFactory;
    import org.puremvc.as3.utilities.loadup.assetloader.model.AssetLoaderFactory;
    import org.puremvc.as3.utilities.loadup.assetloader.interfaces.IAsset;
	import org.puremvc.as3.utilities.loadup.assetloader.interfaces.IAssetForFlex;
    import org.puremvc.as3.utilities.loadup.assetloader.interfaces.IAssetTypeMap;
    import org.puremvc.as3.utilities.loadup.assetloader.interfaces.IAssetFactory;
    import org.puremvc.as3.utilities.loadup.assetloader.interfaces.IAssetLoaderFactory;

    import org.puremvc.as3.demos.flex.loadupforassets.view.components.SingleAssets;

	public class SingleAssetsMediator extends Mediator implements IMediator
	{
		public static const NAME:String = "SingleAssetsMediator";

        protected var progressMessages :ListCollectionView = new ArrayCollection();
        protected var assetGroupProxy :AssetGroupProxy;

		public function SingleAssetsMediator( viewComponent:Object ) {
			super( NAME, viewComponent );
		}
		override public function onRegister() :void {
            singleAssets.addEventListener( ItemClickEvent.ITEM_CLICK, onShowAsset );
            singleAssets.addEventListener( SingleAssets.FINISHED, onFinished );
			singleAssets.progressMessages = progressMessages;

            createSingleAssetsLoadEnv();
            assetGroupProxy = facade.retrieveProxy( ApplicationFacade.SINGLE_ASSETS_GROUP_PROXY_NAME )
                as AssetGroupProxy;
		}
		
		protected function get singleAssets() :SingleAssets {
			return viewComponent as SingleAssets;
		}
		protected function get assetsDisplayComponent() :UIComponent {
			return singleAssets.assetsDisplayComponent as UIComponent;
		}
		/*protected function get assetsDisplayComponent() :DisplayObjectContainer {
			return singleAssets.assetsDisplayComponent as DisplayObjectContainer;
		}*/
		protected function get controlsDisplayComponent() :UIComponent {
			return singleAssets.controlsDisplayComponent as UIComponent;
		}

        protected function onShowAsset( event :ItemClickEvent ) :void {
			var singles :Object = Proxy( facade.retrieveProxy( ApplicationFacade.SINGLE_URLS)).getData() as Object;
            var url :String = singles[ event.label ];
            if ( url )
                processAssetRequest( url );
            else
                Alert.show( "Unknown label for a single url, label=" + event.label );
        }
        protected function onFinished( event:Event ) :void {
            closeSingleAssetsLoadEnv();
            removeSingleAssetsLoadEnv();        }

        protected function processAssetRequest( url :String ) :void {
            var assetPx :AssetProxy = assetGroupProxy.getAssetProxy( url );
            var asset :IAsset = assetGroupProxy.getAsset( url );
            if ( assetPx ) {
                if ( assetPx.isLoaded() ) {
                    addAssetToAssetsDisplayComponent( assetPx.asset );
                    progressMessages.addItemAt( "Displayed an already loaded asset : " + assetPx.asset.url, 0);
                }
                // Else assume loading is in progress; wait for completion and asset to be available
                // via NEW_ASSET_AVAILABLE notification.
            }
            else
                loadSingleAsset( url );
        }

        protected function addAssetToAssetsDisplayComponent( asset :IAsset ) :void {
            var uic :UIComponent = (asset as IAssetForFlex).uiComponent;
            if ( ! uic.parent )
                addAssetPremierToAssetsDisplayComponent( uic );
            else
                addAssetRepeatToAssetsDisplayComponent( uic );
        }
        protected function addAssetPremierToAssetsDisplayComponent( uic :UIComponent ) :void {
            uic.width = 120;
            uic.height = 120;
            assetsDisplayComponent.addChild( uic );
        }
        protected function addAssetRepeatToAssetsDisplayComponent( uic :UIComponent ) :void {
            //var uic :UIComponent = (asset as IAssetForFlex).uiComponent;
            if ( uic is Image ) {
                var bm :Bitmap = new Bitmap( (( uic as Image).content as Bitmap).bitmapData.clone() );
                var disp :Image = new Image();
                disp.load( bm );
                disp.width = 60;
                disp.height = 60;
                assetsDisplayComponent.addChild( disp );
            }
        }

        /**
         *  We choose to ignore the following notifications:<ul>
         *  <li>Loadup.LOADING_PROGRESS</li>
         *  <li>Loadup.LOAD_RESOURCE_TIMED_OUT</li>
         *  <li>Loadup.WAITING_FOR_MORE_RESOURCES</li>
         *  <li>Loadup.ASSET_GROUP_LOAD_PROGRESS</li>
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
                Loadup.URL_REFUSED_PROXY_NAME_ALREADY_EXISTS
                ];
		}

        /**
         *  All the notifications to be handled, whether from Loadup Monitor or
         *  AssetGroupProxy, are of interest only if the notification type matches
         *  the Proxy Name for the Loadup Monitor instance handling these
         *  single assets.
         */
		override public function handleNotification( note:INotification ):void {
		    if ( note.getType() == ApplicationFacade.SINGLE_ASSETS_LU_PROXY_NAME )
		        doHandleNotification( note );
		}
		
		protected function doHandleNotification( note:INotification ):void {
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

			    case Loadup.NEW_ASSET_AVAILABLE:
			        addAssetPremierToAssetsDisplayComponent( (note.getBody() as IAssetForFlex).uiComponent );
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
			        progressMessages.addItemAt( "Loading Complete, All Requested Assets Loaded", 0);
			        break;

			    case Loadup.LOADING_FINISHED_INCOMPLETE:
		            progressMessages.addItemAt( "Loading Finished BUT INCOMPLETE", 0);
			        break;

			    case Loadup.CALL_OUT_OF_SYNC_IGNORED:
		            progressMessages.addItemAt( "LU ignores Call Out Of Sync", 0);
		            // we choose to throw Error
		            throw Error( "LU reports Call Out Of Sync; please debug" );
			        break;
			}
		}

        /**
         *  This could be a Command.
         */
        protected function createSingleAssetsLoadEnv() :void {
            var loadupMon :LoadupMonitorProxy = new LoadupMonitorProxy(
                ApplicationFacade.SINGLE_ASSETS_LU_PROXY_NAME );
            facade.registerProxy( loadupMon );

            // maxRetries 2, retryInterval 10 secs, timeout 300 secs
            var retryParams:RetryParameters = new RetryParameters( 2, 10, 300 );
            loadupMon.defaultRetryPolicy = new RetryPolicy(
                new RetryParameters( 2, 10, 300 ) );

            loadupMon.keepResourceListOpen();
            loadupMon.loadResources();
            // now loadupMon will wait for the first resource to be added

            facade.registerCommand( Loadup.ASSET_LOADED, LoadupResourceLoadedCommand );
            facade.registerCommand( Loadup.ASSET_LOAD_FAILED, LoadupResourceFailedCommand );

            var assetTypeMap :IAssetTypeMap = new FlexAssetTypeMap();
            var assetLoaderFactory :IAssetLoaderFactory = new AssetLoaderFactory( assetTypeMap );

            var groupPx :AssetGroupProxy = new AssetGroupProxy( assetLoaderFactory,
                ApplicationFacade.SINGLE_ASSETS_GROUP_PROXY_NAME, loadupMon );
            facade.registerProxy( groupPx );
        }

        /**
         *  This could be a Command.
         */
        protected function loadSingleAsset( url :String ) :void {
            var loadupMon :LoadupMonitorProxy = facade.retrieveProxy( 
                ApplicationFacade.SINGLE_ASSETS_LU_PROXY_NAME ) as LoadupMonitorProxy;
            var groupPx : AssetGroupProxy = facade.retrieveProxy(
                ApplicationFacade.SINGLE_ASSETS_GROUP_PROXY_NAME ) as AssetGroupProxy;

            if ( facade.hasProxy( url )) {
                sendNotification( Loadup.URL_REFUSED_PROXY_NAME_ALREADY_EXISTS, url, 
                    loadupMon.getProxyName() );
            }
            else {
                var assetTypeMap :IAssetTypeMap = new FlexAssetTypeMap();
                var assetFactory :IAssetFactory = new AssetFactory( assetTypeMap );

                var asset :IAsset = assetFactory.getAsset( url );
                var px :IProxy = new AssetProxy( groupPx, url, asset );
                facade.registerProxy( px );
                groupPx.addAssetProxy ( px );
                loadupMon.addResourceViaLoadupProxy( px as ILoadupProxy );
                // now loadupMon can ask the asset proxy to load this asset.
            }
        }

        /**
         *  This could be a Command.
         */
        protected function closeSingleAssetsLoadEnv() :void {
            var luMon :LoadupMonitorProxy = facade.removeProxy( 
                ApplicationFacade.SINGLE_ASSETS_LU_PROXY_NAME ) as LoadupMonitorProxy;
            luMon.closeResourceList();
        }

        /**
         *  This could be a Command.
         */
        protected function removeSingleAssetsLoadEnv() :void {
            var luMon :LoadupMonitorProxy = facade.removeProxy( 
                ApplicationFacade.SINGLE_ASSETS_LU_PROXY_NAME ) as LoadupMonitorProxy;
            if ( luMon ) luMon.cleanup();

            var groupPx :AssetGroupProxy = facade.retrieveProxy(
                ApplicationFacade.SINGLE_ASSETS_GROUP_PROXY_NAME) as AssetGroupProxy;
            if ( groupPx ) groupPx.cleanupAfterLoading();

            // And remove asset group proxy and asset proxies, if desired;
            // you would not do this if you want to retain the asset group and assets
            // for further read-only use.
            if ( groupPx ) groupPx.cleanup();
        }
	}
}