/*
	PureMVC Flex Demo - LoadupForAssets - loading assets with the Loadup utility
	Copyright (c) 2008 Philip Sexton <philip.sexton@puremvc.org>
	Your reuse is governed by the Creative Commons Attribution 3.0 License
*/
package org.puremvc.as3.demos.flex.loadupforassets.controller {
	
	import org.puremvc.as3.demos.flex.loadupforassets.ApplicationFacade;
	import org.puremvc.as3.demos.flex.loadupforassets.view.ApplicationMediator;
	import org.puremvc.as3.interfaces.ICommand;
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.command.SimpleCommand;
	import org.puremvc.as3.patterns.proxy.Proxy;

	public class StartupCommand extends SimpleCommand implements ICommand {

		/**
		 * Register the essential Proxies and Mediators.
		 */

		override public function execute( note:INotification ) : void {
			// Prepare the model
			facade.registerProxy( new Proxy( ApplicationFacade.URL_GROUP, 
											[   "assets/boats.jpg",
									            "assets/rural1.jpg",
									            "assets/rural2.jpg",
									            "assets/tropical.jpg",
									            "assets/lorem.txt",
									            "assets/oscil.swf"
								        	]) 
								 );
			facade.registerProxy( new Proxy( ApplicationFacade.SINGLE_URLS,
 											{   M : "assets/model_11.png",
            					                V : "assets/Van_Gogh__Landscape_at_Saint_Remy_.png",
 									            C : "assets/gamepad.png"
 								        	}) 
 								 );
					            V : "assets/Van_Gogh__Landscape_at_Saint_Remy_.png",

			// Prepare the View					 
			facade.registerMediator( new ApplicationMediator( note.getBody() ) );
		}
	}
	
}
