/*
	PureMVC Flex Demo - LoadupForAssets - loading assets with the Loadup utility
	Copyright (c) 2008 Philip Sexton <philip.sexton@puremvc.org>
	Your reuse is governed by the Creative Commons Attribution 3.0 License
*/
package org.puremvc.as3.demos.flex.loadupforassets.view {
	
	import org.puremvc.as3.interfaces.IMediator;
	import org.puremvc.as3.patterns.mediator.Mediator;

	public class ApplicationMediator extends Mediator implements IMediator
	{
		public static const NAME:String = "ApplicationMediator";

		public function ApplicationMediator( viewComponent:Object ) {
			super( NAME, viewComponent );
		}
		override public function onRegister() :void {
			facade.registerMediator( new SingleAssetsMediator( app.singleAssets ) );
			facade.registerMediator( new GroupOfAssetsMediator( app.groupOfAssets ) );
		}
		
		protected function get app() :LoadupForAssets {
			return viewComponent as LoadupForAssets;
		}
	}
}