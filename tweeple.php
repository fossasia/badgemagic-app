<?php
/*
Plugin Name: Tweeple
Description: Create custom Twitter feeds using Twitter's latest API.
Version: 0.1.0
Author: Theme Blvd
Author URI: http://themeblvd.com
License: GPL2

    Copyright 2013  Theme Blvd

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License version 2,
    as published by the Free Software Foundation.

    You may NOT assume that you can use any other version of the GPL.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    The license for this software can likely be found here:
    http://www.gnu.org/licenses/gpl-2.0.html

*/

define( 'TWEEPLE_PLUGIN_VERSION', '0.1.0' );
define( 'TWEEPLE_PLUGIN_DIR', dirname( __FILE__ ) );
define( 'TWEEPLE_PLUGIN_URI', plugins_url( '' , __FILE__ ) );
define( 'TWEEPLE_PLUGIN_BASENAME', plugin_basename( __FILE__ ) );

/**
 * Run Tweeple plugin.
 */
function tweeple_init(){

    include_once( TWEEPLE_PLUGIN_DIR . '/inc/class-tweeple.php' );

    Tweeple::get_instance();

}
add_action( 'plugins_loaded', 'tweeple_init' );

/**
 * Frontend actions and filters.
 *
 * The default hooked display functions can be found
 * in /inc/functions.php for reference.
 */
function tweeple_hooks(){

    // Filter the text of a tweet.
    add_filter( 'tweeple_tweet_text', 'tweeple_tweet_text_default' );

    // Display Widget
    add_action( 'tweeple_display_widget', 'tweeple_display_default' );

    // Display Shortcode
    add_action( 'tweeple_display_shortcode', 'tweeple_display_default' );

    // Timestamp
    add_action( 'tweeple_tweet_timestamp', 'tweeple_tweet_timestamp_default' );
    // add_action( 'tweeple_tweet_timestamp', 'tweeple_tweet_timestamp_fancy' );

}
add_action( 'plugins_loaded', 'tweeple_hooks' );