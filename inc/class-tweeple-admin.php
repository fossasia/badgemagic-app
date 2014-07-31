<?php
/**
 * Tweeple Admin
 *
 * @since 0.1.0
 */
class Tweeple_Admin {

	private $parent;
	private $base;
	private $access_id;
	private $sanitized = false;

	/**
	 * Constructor
	 *
	 * @since 0.1.0
	 */
	public function __construct() {

		$this->parent = apply_filters( 'tweeple_admin_parent_slug', 'tools.php' );
		$this->base = apply_filters( 'tweeple_admin_page_base', 'tools_page_tweeple' );

		// Admin page
		add_action( 'admin_enqueue_scripts', array( $this, 'assets' ) );
		add_action( 'admin_menu', array( $this, 'add_page' ) );

		// Settings
		add_action( 'admin_init', array( $this, 'settings' ) );

		// Manage feeds
		add_action( 'admin_init', array( $this, 'save_feed' ) );
		add_action( 'admin_init', array( $this, 'delete_feeds' ) );
		add_action( 'admin_init', array( $this, 'delete_feed_cache' ) );
		add_action( 'current_screen', array( $this, 'access_notice' ) );
	}

	/**
	 * Get parent page for plugin, i.e. tools.php
	 *
	 * @since 0.1.0
	 */
	public function get_parent() {
		return $this->parent;
	}

	/**
	 * Get basename used by WP for page hook.
	 *
	 * @since 0.1.0
	 */
	public function get_base() {
		return $this->base;
	}

	/*--------------------------------------------*/
	/* General Admin Page Setup
	/*--------------------------------------------*/

	/**
	 * Include admin page's CSS/JS
	 *
	 * @since 0.1.0
	 */
	public function assets( $hook ) {
		if ( $hook == $this->base ) {

			wp_enqueue_script( 'tweeple_admin', TWEEPLE_PLUGIN_URI.'/assets/js/admin.js', array('jquery'), TWEEPLE_PLUGIN_VERSION );

			wp_localize_script( 'tweeple_admin', 'tweeple', array(
				'access_id'		=> $this->access_id,
				'clear_msg'		=> __('Are you sure you want to delete your current settings?', 'tweeple'),
				'delete_msg'	=> __('Are you sure you want to delete this Twitter feed?', 'tweeple'),
				'hide_msg'		=> __('Hide Values', 'tweeple'),
				'show_msg'		=> __('Show Values', 'tweeple')
			));

			wp_enqueue_style( 'tweeple_admin', TWEEPLE_PLUGIN_URI.'/assets/css/admin.css', array(), TWEEPLE_PLUGIN_VERSION );
		}

	}

	/**
	 * Register admin page with WP
	 *
	 * @since 0.1.0
	 */
	public function add_page() {

		$admin_page = apply_filters( 'tweeple_feeds_admin_page', array(
			'parent_slug'	=> $this->parent,
			'page_title'	=> 'Tweeple',
			'menu_title'	=> 'Tweeple',
			'capability'	=> 'edit_theme_options',
			'menu_slug'		=> 'tweeple', // don't change this
			'function'		=> array( $this, 'display_page' )
		) );

		add_submenu_page( $admin_page['parent_slug'], $admin_page['page_title'], $admin_page['menu_title'], $admin_page['capability'], $admin_page['menu_slug'], $admin_page['function'] );

	}

	/**
	 * Display admin page wrapper.
	 *
	 * @since 0.1.0
	 */
	public function display_page() {

		// Set active tab ID.
		$active = isset( $_GET['tab'] ) ? $_GET['tab'] : 'feeds';

		?>
		<div id="tweeple">
			<div class="wrap">

 				<div class="tb-screen-icon" id="icon-tweeple"></div>

				<h2 class="nav-tab-wrapper tweeple-nav-tab-wrapper">
					<a href="<?php echo admin_url( $this->parent.'?page=tweeple&tab=feeds' ); ?>" class="nav-tab<?php if ($active == 'feeds') echo ' nav-tab-active'; ?>">
						<?php _e('Twitter Feeds', 'tweeple'); ?>
					</a>
					<?php if ( $active == 'edit' ) : ?>
						<a href="<?php echo admin_url( $this->parent.'?page=tweeple&tab=edit&id='.$_GET['id'] ); ?>" class="nav-tab<?php if ($active == 'edit') echo ' nav-tab-active'; ?>">
							<?php _e('Edit Feed', 'tweeple'); ?>
						</a>
					<?php endif; ?>
					<a href="<?php echo admin_url( $this->parent.'?page=tweeple&tab=add_feed' ); ?>" class="nav-tab<?php if ($active == 'add_feed') echo ' nav-tab-active'; ?>">
						<?php _e('Add Feed', 'tweeple'); ?>
					</a>
					<a href="<?php echo admin_url( $this->parent.'?page=tweeple&tab=authentication' ); ?>" class="nav-tab<?php if ($active == 'authentication') echo ' nav-tab-active'; ?>">
						<?php _e('Authentication', 'tweeple'); ?>
					</a>
				</h2>

				<?php
				switch( $active ) {
					case 'feeds' :
						$this->page_feeds();
						break;

					case 'edit' :
						$this->page_edit();
						break;

					case 'add_feed' :
						$this->page_add_feed();
						break;

					case 'authentication' :
						$this->page_authentication();
						break;
				}
				?>

			</div><!-- .wrap (end) -->
		</div><!-- #tweeple (end) -->
		<?php
	}

	/**
	 * Get table of a custom post type.
	 *
	 * @since 0.1.0
	 */
	private function posts_table( $post_type, $columns, $manual_delete = null ) {

		// Grab some details for post type
		$post_type_object = get_post_type_object($post_type);
		$name = $post_type_object->labels->name;
		$singular_name = $post_type_object->labels->singular_name;

		// Get posts
		$posts = get_posts( array( 'post_type' => $post_type, 'numberposts' => -1, 'orderby' => 'title', 'order' => 'ASC' ) );

		// Create nonce for clearing cache.
		$nonce = wp_create_nonce( 'tweeple_cache' );

		// Setup header/footer
		$header = '<tr>';
		$header .= '<th scope="col" id="cb" class="manage-column column-cb check-column"><input type="checkbox"></th>';
		foreach( $columns as $column ) {
			$header .= '<th class="head-'.$column['type'].'">'.$column['name'].'</th>';
		}
		$header .= '</tr>';

		// Start main output
		$output  = '<table class="widefat">';
		$output .= '<div class="tablenav top">';
		$output .= '<div class="alignleft actions">';
		$output .= '<select name="action">';
		$output .= '<option value="-1" selected="selected">'.__( 'Bulk Actions', 'themeblvd' ).'</option>';
		$output .= '<option value="trash">'.__( 'Delete', 'themeblvd' ).' '.$name.'</option>';
		$output .= '</select>';
		$output .= '<input type="submit" id="doaction" class="button-secondary action" value="'.__( 'Apply', 'themeblvd' ).'">';
		$output .= '</div>';
		$output .= '<div class="alignright tablenav-pages">';
		$output .= '<span class="displaying-num">'.sprintf( _n( '1 '.$singular_name, '%s '.$name, count($posts) ), number_format_i18n( count($posts) ) ).'</span>';
		$output .= '</div>';
		$output .= '<div class="clear"></div>';
		$output .= '</div>';

		// Table header
		$output .= '<thead>';
		$output .= $header;
		$output .= '</thead>';

		// Table footer
		$output .= '<tfoot>';
		$output .= $header;
		$output .= '</tfoot>';

		// Table body
		$output .= '<tbody>';
		if ( ! empty( $posts ) ) {

			$num = count( $columns ) + 1; // number of columns + the checkbox column

			foreach( $posts as $post ) {
				$output .= '<tr id="row-'.esc_attr($post->ID).'">';
				$output .= '<th scope="row" class="check-column"><input type="checkbox" name="posts[]" value="'.$post->ID.'"></th>';
				foreach( $columns as $column ) {
					switch( $column['type'] ) {
						case 'title' :
							$edit_url = admin_url( $this->parent.'?page=tweeple&tab=edit&id='.esc_attr($post->ID) );
							$output .= '<td class="post-title page-title column-title">';
							$output .= '<strong><a href="'.$edit_url.'" class="title-link edit-'.$post_type.'" title="'.__( 'Edit', 'tweeple' ).'">'.stripslashes(esc_html($post->post_title)).'</strong></a>';
							$output .= '<div class="row-actions">';
							$output .= '<span class="edit">';
							$output .= '<a href="'.$edit_url.'" class="edit-post edit-'.$post_type.'" title="'.__( 'Edit', 'themeblvd' ).'">'.__( 'Edit', 'tweeple' ).'</a> | ';
							$output .= '</span>';
							$output .= '<span class="trash">';
							$output .= '<a title="'.__( 'Delete', 'tweeple' ).'" href="#'.$post->ID.'">'.__( 'Delete', 'tweeple' ).'</a>';
							$output .= '</span>';
							$output .= '</div>';
							break;

						case 'id' :
							$output .= '<td class="post-id">';
							$output .= esc_html( $post->ID );
							break;

						case 'slug' :
							$output .= '<td class="post-slug">';
							$output .= esc_html( $post->post_name );
							break;

						case 'meta' :
							$output .= '<td class="post-meta-'.esc_attr($column['config']).'">';
							$meta = get_post_meta( $post->ID, $column['config'], true );
							if ( isset( $column['inner'] ) ) {
								if ( isset( $meta[$column['inner']] ) ) {
									$output .= esc_html( $meta[$column['inner']] );
								}
							} else {
								$output .= esc_html( $meta );
							}
							break;

						case 'cache' :
							$output .= '<td class="cache">';
							$output .= '<div class="cache-overlay">';

							if ( ! get_transient( 'tweeple_'.$post->ID ) ) {
								$output .= '<span class="inactive"></span>';
							}

							$url = admin_url( $this->parent.'?page=tweeple&tab=feeds&tweeple=cache&id='.esc_attr($post->ID).'&_wpnonce='.$nonce );
							$output .= sprintf( '<a href="%s" data-id="%s" title="%s" class="clear-cache">%s</a>', $url, esc_attr( $post->ID ), __( 'Delete current cache', 'tweeple' ), __( 'Delete current cache', 'tweeple' ) );

							$output .= '</div><!-- .cache-overlay (end) -->';
							break;

						case 'feed_type' :
							$output .= '<td class="feed-type">';

							$type = get_post_meta( $post->ID, 'feed_type', true );

							if ( $type == 'user_timeline' ) {

								$screen_name = get_post_meta( $post->ID, 'screen_name', true );

								if ( $screen_name ) {
									$output .= sprintf( '@%s', esc_html( $screen_name ) );
								} else {
									$output .= sprintf( '<em>%s</em>', __('This feed is missing a username.', 'tweeple') );
								}

							} else if ( $type == 'search' ) {

								$search = get_post_meta( $post->ID, 'search', true );

								if ( $search ) {

									if ( strpos( $search, '#' ) !== false ) {
										$output .= sprintf( '%s <a href="https://twitter.com/search?q=%s" class="hashtag" target="_blank">%s</a>', __('Trending at', 'tweeple'), urlencode( esc_attr( $search ) ), esc_html( $search ) );
									} else {
										$output .= sprintf( '%s "%s"', __( 'Search for', 'tweeple' ), esc_html( $search ) );
									}

								} else {

									$output .= '<em>'.__('This feed is missing a search term.', 'tweeple').'</em>';

								}

							} else if ( $type == 'list' ) {

								$list = get_post_meta( $post->ID, 'slug', true );
								$screen_name = get_post_meta( $post->ID, 'owner_screen_name', true );

								if ( $screen_name && $list ) {
									$output .= sprintf( 'List "%s" from %s', esc_attr( $list ), esc_attr( $screen_name ) );
								} else {
									$output .= sprintf( '<em>%s</em>', __('This feed is missing a list slug and/or owner username.', 'tweeple') );
								}

							} else if ( $type == 'favorites' ) {

								$screen_name = get_post_meta( $post->ID, 'screen_name', true );

								if ( $screen_name ) {
									$output .= sprintf( "%s's favorites", esc_attr( $screen_name ) );
								} else {
									$output .= sprintf( '<em>%s</em>', __('This feed is missing a username.', 'tweeple') );
								}

							}
							break;

					}
					$output .= '</td>';
				}
				$output .= '</tr>';
			}
		} else {
			$num = count($columns) + 1;
			$output .= sprintf('<tr><td colspan="%s">%s</td></tr>', $num, __('No items have been created yet. Click the Add tab above to get started.', 'tweeple') );
		}
		$output .= '</tbody>';
		$output .= '</table>';

		return $output;
	}

	/**
	 * Get form for adding and editing a feed.
	 *
	 * @since 0.1.0
	 */
	function feed_config( $id = 0, $value = array() ) {

		$defaults = apply_filters('tweeple_edit_feed_defaults', array(
			'feed_type'			=> 'user_timeline',	// Type of feed - user_timeline, search, list, favorites
			'screen_name'		=> '', 				// Twitter username for user timeline
			'slug'				=> '', 				// Twitter list slug
			'owner_screen_name'	=> '', 				// Twitter username that list belongs to
			'search'			=> '',				// Search term or hashtag
			'result_type'		=> 'mixed',			// Search result type - mixed, popular, recent
			'exclude_retweets'	=> 'no',			// Exclude retweets (timeline only)
			'exclude_replies'	=> 'no',			// Exclude @replies? (timeline only)
			'time'				=> 'yes',			// Display time?
			'count'				=> '3',				// Num of tweets to pull
			'encode'			=> 'yes',			// Whether to UTF-8 encode tweets or not
			'cache'				=> '7200', 			// 2 hours
			'raw_count'			=> '10' 			// Raw tweet count from response before any parsing
		));
		$value = wp_parse_args( $value, $defaults );

		$post = get_post( $id );
		if ( $post ) {
			$name = $post->post_title;
		} else {
			$name = '';
		}

		settings_errors( 'tweeple_feed_config' );

		$learn_more = __('Learn More', 'tweeple' );
		$feed_type = $value['feed_type'];
		?>
		<form id="feed-config" action="" method="post">

			<?php $nonce = wp_create_nonce( 'tweeple_feed_config' ); ?>
			<input name="_wpnonce" value="<?php echo $nonce; ?>" type="hidden" />
			<input name="tweeple_feed_id" type="hidden" value="<?php echo $id; ?>" />

			<div class="metabox-holder">

				<!-- FEED TYPE (start) -->

				<div class="feed-type-wrap">
					<select name="feed_type">
						<option value="user_timeline" <?php selected( 'user_timeline', $feed_type ); ?>>
							<?php _e( 'Twitter user\'s timeline', 'tweeple' ); ?>
						</option>
						<option value="list" <?php selected( 'list', $feed_type ); ?>>
							<?php _e( 'Twitter user\'s public list', 'tweeple' ); ?>
						</option>
						<option value="favorites" <?php selected( 'favorites', $feed_type ); ?>>
							<?php _e( 'Twitter user\'s favorite tweets', 'tweeple' ); ?>
						</option>
						<option value="search" <?php selected( 'search', $feed_type ); ?>>
							<?php _e( 'Search term or hashtag', 'tweeple' ); ?>
						</option>
					</select>
					<span class="feed-type-desc note">
						<?php _e( 'Select the type of Twitter feed.', 'tweeple' ); ?>
					</span>
				</div>

				<!-- FEED TYPE (end) -->

				<!-- FEED SETUP (start) -->

				<div class="postbox inner-section">

					<h3 class="toggle toggle-user_timeline <?php $this->hide_section( 'user_timeline', $feed_type ); ?>"><?php _e('Twitter User\'s Timeline', 'tweeple'); ?></h3>
					<h3 class="toggle toggle-list <?php $this->hide_section( 'list', $feed_type ); ?>"><?php _e('Twitter User\'s Public List', 'tweeple'); ?></h3>
					<h3 class="toggle toggle-favorites <?php $this->hide_section( 'favorites', $feed_type ); ?>"><?php _e('Twitter User\'s Favorites', 'tweeple'); ?></h3>
					<h3 class="toggle toggle-search <?php $this->hide_section( 'search', $feed_type ); ?>"><?php _e('Search Term or Hashtag', 'tweeple'); ?></h3>

					<div class="section col-wrap">
						<div class="col-left">
							<div class="col-inner control">
								<h4><?php _e('Feed Name', 'tweeple'); ?></h4>
								<input name="name" value="<?php echo $name; ?>" type="text" />
							</div>
						</div>
						<div class="col-right">
							<div class="col-inner">
								<div class="desc">
									<p><?php _e('Enter your own user-friendly name to associate with this Twitter feed. Example: My Twitter Feed', 'tweeple'); ?></p>
								</div>
							</div>
						</div>
					</div><!-- .section (end) -->

					<div class="section col-wrap toggle toggle-user_timeline toggle-favorites <?php $this->hide_section( array('user_timeline', 'favorites'), $feed_type ); ?>">
						<div class="col-left">
							<div class="col-inner control">
								<h4><?php _e('Twitter Username', 'tweeple'); ?></h4>
								<input name="screen_name" value="<?php echo $value['screen_name']; ?>" type="text" />
							</div>
						</div>
						<div class="col-right">
							<div class="col-inner">
								<div class="desc">
									<p><?php _e('Enter the username of a Twitter account.<br />Example: ThemeBlvd', 'tweeple'); ?></p>
								</div>
							</div>
						</div>
					</div><!-- .section (end) -->

					<div class="section col-wrap toggle toggle-list <?php $this->hide_section( array('list'), $feed_type ); ?>">
						<div class="col-left">
							<div class="col-inner control">
								<h4><?php _e('List Slug', 'tweeple'); ?></h4>
								<input name="slug" value="<?php echo $value['slug']; ?>" type="text" />
							</div>
						</div>
						<div class="col-right">
							<div class="col-inner">
								<div class="desc">
									<p><?php _e('Enter the slug for a Twitter list.<br />Example: mylist', 'tweeple'); ?></p>
								</div>
							</div>
						</div>
					</div><!-- .section (end) -->

					<div class="section col-wrap toggle toggle-list <?php $this->hide_section( array('list'), $feed_type ); ?>">
						<div class="col-left">
							<div class="col-inner control">
								<h4><?php _e('List Owner\'s Username', 'tweeple'); ?></h4>
								<input name="owner_screen_name" value="<?php echo $value['owner_screen_name']; ?>" type="text" />
							</div>
						</div>
						<div class="col-right">
							<div class="col-inner">
								<div class="desc">
									<p><?php _e('Enter the username of the Twitter account the above list belongs to. Example: ThemeBlvd', 'tweeple'); ?></p>
								</div>
							</div>
						</div>
					</div><!-- .section (end) -->

					<div class="section col-wrap toggle toggle-search <?php $this->hide_section( array('search'), $feed_type ); ?>">
						<div class="col-left">
							<div class="col-inner control">
								<h4><?php _e('Search Term', 'tweeple'); ?></h4>
								<input name="search" value="<?php echo $value['search']; ?>" type="text" />
							</div>
						</div>
						<div class="col-right">
							<div class="col-inner">
								<div class="desc">
									<p><?php _e('Enter a search term to pull tweets from Twitter. This can be simple phrase, word, or hashtag. Example: #cats', 'tweeple'); ?></p>
								</div>
							</div>
						</div>
					</div><!-- .section (end) -->

					<div class="section col-wrap toggle toggle-search <?php $this->hide_section( array('search'), $feed_type ); ?>">
						<div class="col-left">
							<div class="col-inner control">
								<h4><?php _e('Search Results Type', 'tweeple'); ?></h4>
								<select name="result_type">
									<option value="popular" <?php selected( 'popular', $value['result_type'] ); ?>>
										<?php _e( 'Most Popular', 'tweeple' ); ?>
									</option>
									<option value="recent" <?php selected( 'recent', $value['result_type'] ); ?>>
										<?php _e( 'Most Recent', 'tweeple' ); ?>
									</option>
									<option value="mixed" <?php selected( 'mixed', $value['result_type'] ); ?>>
										<?php _e( 'Mixed', 'tweeple' ); ?>
									</option>
								</select>
							</div>
						</div>
						<div class="col-right">
							<div class="col-inner">
								<div class="desc">
									<p><?php _e('Select the type of results to return for the above search query.', 'tweeple'); ?></p>
								</div>
							</div>
						</div>
					</div><!-- .section (end) -->

					<div class="section col-wrap toggle toggle-user_timeline toggle-list <?php $this->hide_section( array('user_timeline', 'list'), $feed_type ); ?>">
						<div class="col-left">
							<div class="col-inner control">
								<h4><?php _e('Exclude retweets?', 'tweeple'); ?></h4>
								<select name="exclude_retweets">
									<option value="yes" <?php selected( 'yes', $value['exclude_retweets'] ); ?>>
										<?php _e( 'Yes', 'tweeple' ); ?>
									</option>
									<option value="no" <?php selected( 'no', $value['exclude_retweets'] ); ?>>
										<?php _e( 'No', 'tweeple' ); ?>
									</option>
								</select>
							</div>
						</div>
						<div class="col-right">
							<div class="col-inner">
								<div class="desc">
									<p><?php _e('Select if you\'d like retweets excluded from the list of tweets or not.', 'tweeple'); ?></p>
								</div>
							</div>
						</div>
					</div><!-- .section (end) -->

					<div class="section col-wrap toggle toggle-user_timeline <?php $this->hide_section( array('user_timeline'), $feed_type ); ?>">
						<div class="col-left">
							<div class="col-inner control">
								<h4><?php _e('Exclude @replies?', 'tweeple'); ?></h4>
								<select name="exclude_replies">
									<option value="yes" <?php selected( 'yes', $value['exclude_replies'] ); ?>>
										<?php _e( 'Yes', 'tweeple' ); ?>
									</option>
									<option value="no" <?php selected( 'no', $value['exclude_replies'] ); ?>>
										<?php _e( 'No', 'tweeple' ); ?>
									</option>
								</select>
							</div>
						</div>
						<div class="col-right">
							<div class="col-inner">
								<div class="desc">
									<p><?php _e('Select if you\'d like @replies excluded from the list of tweets or not.', 'tweeple'); ?></p>
								</div>
							</div>
						</div>
					</div><!-- .section (end) -->

					<div class="section col-wrap">
						<div class="col-left">
							<div class="col-inner control">
								<h4><?php _e('Display Tweet details?', 'tweeple'); ?></h4>
								<select name="time">
									<option value="yes" <?php selected( 'yes', $value['time'] ); ?>>
										<?php _e( 'Yes', 'tweeple' ); ?>
									</option>
									<option value="no" <?php selected( 'no', $value['time'] ); ?>>
										<?php _e( 'No', 'tweeple' ); ?>
									</option>
								</select>
							</div>
						</div>
						<div class="col-right">
							<div class="col-inner">
								<div class="desc">
									<p>
										<?php _e('Display a timestamp for the Tweet, or whatever your current theme has setup to be displayed for each Tweet\'s meta.', 'tweeple'); ?><br />
										<?php printf( '<a href="https://github.com/themeblvd/Tweeple/wiki/How-to-create-your-own-meta-display-for-tweets">%s</a>', $learn_more ); ?>
									</p>
								</div>
							</div>
						</div>
					</div><!-- .section (end) -->

					<div class="section col-wrap">
						<div class="col-left">
							<div class="col-inner control">
								<h4><?php _e('Tweet Display Limit', 'tweeple'); ?></h4>
								<select name="count">
									<?php
									$limit = apply_filters( 'tweeple_count_limit', 20 );
									$current = intval( esc_attr( $value['count'] ) );
									for ( $i = 1; $i <= $limit; $i++ ) {
										printf( '<option value="%s" %s>%s</option>', $i, selected( $i, $current, false ), $i );
									}
									?>
								</select>
							</div>
						</div>
						<div class="col-right">
							<div class="col-inner">
								<div class="desc">
									<p><?php _e( 'Select how many Tweets you\'d like displayed for this feed.', 'tweeple' ); ?></p>
								</div>
							</div>
						</div>
					</div><!-- .section (end) -->

					<div class="section col-wrap">
						<div class="col-left">
							<div class="col-inner control">
								<h4><?php _e('UTF-8 Text Encoding', 'tweeple'); ?></h4>
								<select name="encode">
									<option value="yes" <?php selected( 'yes', $value['encode'] ); ?>>
										<?php _e( 'Yes', 'tweeple' ); ?>
									</option>
									<option value="no" <?php selected( 'no', $value['encode'] ); ?>>
										<?php _e( 'No', 'tweeple' ); ?>
									</option>
								</select>
							</div>
						</div>
						<div class="col-right">
							<div class="col-inner">
								<div class="desc">
									<p><?php _e( 'If you\'re having problems displaying characters or words in your language, try disabling UTF-8 encoding.', 'tweeple' ); ?></p>
								</div>
							</div>
						</div>
					</div><!-- .section (end) -->

				</div><!-- .postbox (end) -->

				<!-- FEED SETUP (end) -->

				<!-- PERFORMANCE (start) -->

				<div class="postbox inner-section">

					<h3><?php _e('Performance', 'tweeple'); ?></h3>

					<div class="section col-wrap">
						<div class="col-left">
							<div class="col-inner control">
								<h4><?php _e('Cache Time', 'tweeple'); ?></h4>
								<input class="field" name="cache" value="<?php echo esc_attr( $value['cache'] ); ?>" type="text" />
							</div>
						</div>
						<div class="col-right">
							<div class="col-inner">
								<div class="desc">
									<p>
										<?php _e( 'Enter the number of seconds to wait between pulling data from Twitter. For example, "7200" will be two hours.', 'tweeple' ); ?><br />
										<?php printf( '<a href="https://github.com/themeblvd/Tweeple/wiki/Caching">%s</a>', $learn_more ); ?>
									</p>
								</div>
							</div>
						</div>
					</div>

					<div class="section col-wrap">
						<div class="col-left">
							<div class="col-inner control">
								<h4><?php _e('Raw Tweet Count', 'tweeple'); ?></h4>
								<select name="raw_count">
									<?php
									$raw_limit = apply_filters( 'tweeple_raw_count_limit', 30 );
									$current = intval( esc_attr( $value['raw_count'] ) );
									for ( $i = 1; $i <= $raw_limit; $i++ ) {
										printf( '<option value="%s" %s>%s</option>', $i, selected( $i, $current, false ), $i );
									}
									?>
								</select>
							</div>
						</div>
						<div class="col-right">
							<div class="col-inner">
								<div class="desc">
									<p>
										<?php _e( 'Select the raw number of Tweets to pull from Twitter before doing any parsing, like excluding @replies and retweets.', 'tweeple' ); ?><br />
										<?php printf( '<a href="https://github.com/themeblvd/Tweeple/wiki/Tweet-Limit">%s</a>', $learn_more ); ?>
									</p>
								</div>
							</div>
						</div>
					</div>

				</div><!-- .postbox (end) -->

				<!-- PERFORMANCE (end) -->

				<!-- SUBMIT (start) -->
				<div class="options-submit">
					<?php $text = intval($id) > 0 ? __( 'Update Twitter Feed', 'tweeple' ) : __( 'Add Twitter Feed', 'tweeple' ); ?>
					<input type="submit" class="button-primary" value="<?php echo $text; ?>" />
				</div><!-- .options-submit (end) -->
				<!-- SUBMIT (end) -->
			</div>
		</form>
		<?php
	}

	/**
	 * Get form for adding and editing a feed.
	 *
	 * @since 0.1.0
	 *
	 * @param mixed $section_types Current section's types, could be single string or array
	 * @param string $feed_type Current type of feed
	 */
	function hide_section( $section_type, $feed_type ) {

		if ( is_array( $section_type ) ) {

			if ( ! in_array( $feed_type, $section_type ) ) {
				echo 'hide';
			}

			return;
		}

		if ( $section_type != $feed_type ) {
			echo 'hide';
		}

	}

	/**
	 * Save feed on form submissions.
	 *
	 * @since 0.1.0
	 */
	public function save_feed() {

		// Verify this is our form.
		if ( ! isset( $_POST['tweeple_feed_id'] ) ) {
			return;
		}

		// Verify security nonce on our form.
		if ( ! wp_verify_nonce( $_POST['_wpnonce'], 'tweeple_feed_config' ) ) {
			return;
		}

		$name = wp_kses( $_POST['name'], array() );
		$post_id = intval($_POST['tweeple_feed_id']);
		$message = $name.' '.__('Twitter feed updated.', 'tweeple');

		// If post ID is 0, it means this is new feed.
		if ( $post_id == 0 ) {

			// Setup arguments for new feed post.
			$args = array(
				'post_type'			=> 'tweeple_feed',
				'post_title'		=> $name,
				'post_status' 		=> 'publish',
				'comment_status'	=> 'closed',
				'ping_status'		=> 'closed'
			);

			// Create new post
			$post_id = wp_insert_post( $args );

			// Change success message because the user
			// is creating a new feed.
			$message = $name.' '.__( 'Twitter feed created.', 'tweeple' );

		} else {

			// Update name of post
			wp_update_post( array( 'ID' => $post_id, 'post_title' => $name ) );

			// Dump cache
			delete_transient( 'tweeple_'.$post_id );

		}

		// Save and sanitize meta data for new feed.
		$settings = array(
			'feed_type'			=> $_POST['feed_type'],
			'screen_name'		=> $_POST['screen_name'],
			'slug'				=> $_POST['slug'],
			'owner_screen_name'	=> $_POST['owner_screen_name'],
			'search'			=> $_POST['search'],
			'result_type'		=> $_POST['result_type'],
			'exclude_retweets'	=> $_POST['exclude_retweets'],
			'exclude_replies'	=> $_POST['exclude_replies'],
			'count'				=> $_POST['count'],
			'time'				=> $_POST['time'],
			'encode'			=> $_POST['encode'],
			'cache'				=> $_POST['cache'],
			'raw_count'			=> $_POST['raw_count']
		);
		$this->save_feed_meta( $post_id, $settings );

		// Add success message
		add_settings_error( 'tweeple_feed_config', 'save_options', $message, 'updated fade' );

	}

	/**
	 * Save and sanitize meta data for tweeple_feed post.
	 *
	 * @since 0.1.0
	 */
	public function save_feed_meta( $post_id, $settings ) {

		// Verify a settings array was passed into sanitize
		if ( ! is_array( $settings ) ) {
			return;
		}

		// Accepted feed types
		$feed_types = apply_filters( 'tweeple_feed_types', array( 'user_timeline', 'search', 'list', 'favorites' ) );

		// Accepted search result types
		$result_types = apply_filters( 'tweeple_result_types', array( 'mixed', 'popular', 'recent' ) );

		// Yes/no type options
		$yes_no = apply_filters( 'tweeple_yes_no_options', array( 'exclude_replies', 'exclude_retweets', 'time' ) );

		// Maximum count limit for number of tweets pulled
		$raw_limit = apply_filters( 'tweeple_raw_count_limit', 30 );
		$display_limit = apply_filters( 'tweeple_count_limit', 20 );

		// Raw Count
		$raw_count = intval( $settings['raw_count'] );

		if ( $raw_count < 1 || $raw_count > $raw_limit ) {
			$settings['raw_count'] = 10; // Default fallback count
		}

		// Display Count
		$display_count = intval( $settings['count'] );

		if ( $display_count < 1 || $display_count > $display_limit || $display_count > $settings['raw_count'] ) {
			$settings['count'] = $settings['raw_count'];
		}

		foreach ( $settings as $key => $value ){

			// Strip out anything bad.
			$value = wp_kses( $value, array() );

			// Make sure user doesn't put "@" sign in front
			// of Twitter username.
			if ( $key == 'screen_name' ) {
				$value = str_replace('@', '', $value);
			}

			// Verify feed type
			if ( $key == 'feed_type' && ! in_array( $value, $feed_types ) ) {
				$value = $feed_types[0];
			}

			// Verify search result types
			if ( $key == 'result_type' && ! in_array( $value, $result_types ) ) {
				$value = $result_types[0];
			}

			// Verify Yes/No type select options
			if ( in_array( $key, $yes_no ) && ( $value != 'yes' && $value != 'no' ) ) {
				$value = 'no';
			}

			// Verify cache time. Don't allow user to set
			// cache time less than once a minute.
			if ( $key == 'cache' ) {
				$value = intval( $value );
				$minimum = apply_filters( 'tweeple_cache_time_minimum', 60 );
				if ( $value < $minimum ) {
					$value = $minimum;
				}
			}

			// Allow extended sanitization
			$value = apply_filters( 'tweeple_sanitize_meta', $value, $key );

			// Save meta field
			update_post_meta( $post_id, $key, $value );

		}
	}

	/**
	 * Display notice if "Authorization" settings
	 * haven't been setup yet.
	 *
	 * @since 0.2.0
	 */
	public function access_notice() {

		// Make sure it's our admin page.
		$current = get_current_screen();
		if ( $current->base != $this->base ) {
			return;
		}

		$is_valid = true;
		$settings = get_option( $this->access_id );

		if ( ! $settings ) {
			$is_valid = false;
		}

		// Ok, so the settings exist, but were all of them stored?
		if ( $is_valid ) {
			$options = array( 'consumer_key', 'consumer_secret', 'user_token', 'user_secret' );
			foreach ( $options as $option ) {
				if ( empty( $settings[$option] ) ) {
					$is_valid = false;
					break;
				}
			}
		}

		// If everything is still valid, we
		// can get out of here.
		if ( $is_valid ) {
			return;
		}

		// BUT, if we're still here, it means settings haven't
		// been setup right.
		$link = sprintf( '<a href="%s">%s</a>', admin_url( $this->parent.'?page=tweeple&tab=authentication' ), __('authentication settings', 'tweeple') );
		$message = sprintf( __( 'Before any feeds can pull from Twitter, you need to setup all %s.', 'tweeple' ), $link );

		add_settings_error( 'tweeple_feed_manage', 'save_options', $message, 'error' );
		add_settings_error( 'tweeple_feed_config', 'save_options', $message, 'error' );
	}

	/*--------------------------------------------*/
	/* "Twitter Feeds" Admin Page
	/*--------------------------------------------*/

	/**
	 * Display "Feeds" admin page tab
	 *
	 * @since 0.1.0
	 */
	private function page_feeds() {

		// Setup columns for table to display feeds
		$columns = apply_filters( 'tweeple_manage_feeds', array(
			array(
				'name' 	=> __( 'Feed Title', 'tweeple' ),
				'type'	=> 'title',
			),
			array(
				'name' 	=> __( 'Feed ID', 'tweeple' ),
				'type' 	=> 'id',
			),
			array(
				'name' 	=> __( 'Feed Type', 'tweeple' ),
				'type' 	=> 'feed_type'
			),
			array(
				'name' 	=> __( 'Cache', 'tweeple' ),
				'type' 	=> 'cache',
			)
		));

		// Display notices
		settings_errors( 'tweeple_feed_manage' );

		// Display table
		echo '<form id="tweeple-feeds-manage" action="" method="post">';

		$nonce = wp_create_nonce( 'tweeple_feed_manage' );
		printf( '<input name="_tweeple_feed_manage_nonce" value="%s" type="hidden" />', $nonce );

		echo $this->posts_table( 'tweeple_feed', $columns, array( 'tweeple_feed_manage' => $nonce ) );

		echo '</form>';
	}

	/**
	 * Delete feeds in bulk or individually.
	 *
	 * @since 0.1.0
	 */
	public function delete_feeds() {

		// Verify this is our form.
		if ( ! isset( $_POST['_tweeple_feed_manage_nonce'] ) ) {
			return;
		}

		// Verify security nonce on our form.
		if ( ! wp_verify_nonce( $_POST['_tweeple_feed_manage_nonce'], 'tweeple_feed_manage' ) ) {
			return;
		}

		// Bulk action
		if ( isset( $_POST['posts'] ) && is_array( $_POST['posts'] ) ) {

			// Don't do anything if we're not deleting posts
			// or no posts were passed.
			if ( $_POST['action'] != 'trash' ) {
				return;
			}

			// Loop through post ID's and delete them.
			foreach( $_POST['posts'] as $post_id ) {
				wp_delete_post( $post_id ); // Can still be retrieved from trash
			}

			// Display message
			add_settings_error( 'tweeple_feed_manage', 'tweeple_feed_manage', __( 'Selected Twitter feeds deleted.', 'tweeple' ), 'error fade' );

			return;
		}

		// Delete single post
		if ( isset( $_POST['delete-post'] ) ) {
			wp_delete_post( $_POST['delete-post'] ); // Can still be retrieved from trash
		}

		// Add message
		add_settings_error( 'tweeple_feed_manage', 'tweeple_feed_manage', __( 'Twtter feed deleted.', 'tweeple' ), 'error fade' );
	}

	/**
	 * Delete the cache for a feed.
	 *
	 * @since 0.1.0
	 */
	public function delete_feed_cache() {

		// Verfiy this is our action
		if ( ! isset( $_GET['tweeple'] ) || $_GET['tweeple'] != 'cache' ) {
			return;
		}

		// Verify security nonce on our form
		if ( ! wp_verify_nonce( $_GET['_wpnonce'], 'tweeple_cache' ) ) {
			return;
		}

		// Make sure a post ID greater than 0 was passed
		if ( ! isset( $_GET['id'] ) || intval( $_GET['id'] ) <= 0 ) {
			return;
		}

		// Delete transient
		delete_transient( 'tweeple_'.$_GET['id'] );

		// Add success message
		add_settings_error( 'tweeple_cache', 'tweeple_cache', __( 'Cache cleared for Tweeter feed.', 'tweeple' ), 'updated fade' );
	}

	/*--------------------------------------------*/
	/* "Edit Feed" Admin Page
	/*--------------------------------------------*/

	/**
	 * Edit a feed.
	 *
	 * @since 0.1.0
	 */
	public function page_edit(){

		$post_id = isset( $_GET['id'] ) ? $_GET['id'] : 0;

		$post = get_post($post_id);

		// Check for valid post
		if ( ! $post ) {
			echo '<div class="error settings-error">';
			echo '<p><strong>'.__('No valid Twitter Feed found to edit.', 'tweeple').'</strong></p>';
			echo '</div>';
			return;
		}

		$settings = array(
			'feed_type'			=> get_post_meta( $post_id, 'feed_type', true ),
			'screen_name'		=> get_post_meta( $post_id, 'screen_name', true ),
			'slug'				=> get_post_meta( $post_id, 'slug', true ),
			'owner_screen_name'	=> get_post_meta( $post_id, 'owner_screen_name', true ),
			'search'			=> get_post_meta( $post_id, 'search', true ),
			'result_type'		=> get_post_meta( $post_id, 'result_type', true ),
			'exclude_retweets'	=> get_post_meta( $post_id, 'exclude_retweets', true ),
			'exclude_replies'	=> get_post_meta( $post_id, 'exclude_replies', true ),
			'time'				=> get_post_meta( $post_id, 'time', true ),
			'count'				=> get_post_meta( $post_id, 'count', true ),
			'encode'			=> get_post_meta( $post_id, 'encode', true ),
			'cache'				=> get_post_meta( $post_id, 'cache', true ),
			'raw_count'			=> get_post_meta( $post_id, 'raw_count', true )
		);

		$this->feed_config( $post_id, $settings );
	}

	/*--------------------------------------------*/
	/* "Add Feed" Admin Page
	/*--------------------------------------------*/

	/**
	 * Display "Add Feed" admin page tab
	 *
	 * @since 0.1.0
	 */
	private function page_add_feed() {

		// Display form to add new feed.
		$this->feed_config();

	}

	/*--------------------------------------------*/
	/* "Authentication" Admin Page
	/*--------------------------------------------*/

	/**
	 * Display "Authentication" admin page tab
	 *
	 * @since 0.1.0
	 */
	private function page_authentication() {

		$settings = $this->get_settings('access');

		settings_errors( $this->access_id );
		?>
		<form id="tweeple-authentication" action="options.php" method="post">

			<?php settings_fields( $this->access_id ); ?>

			<div class="metabox-holder">

				<div class="authentication-help">
					<p><?php printf(__('In order to access Twitter API, you\'ll need to login to Twitter and create an application at %s. After you\'ve done this, enter your OAuth settings and access token below.', 'tweeple'), '<a href="https://dev.twitter.com/apps" target="_blank">dev.twitter.com/apps</a>'); ?></p>
					<p><a href="http://wordpress.org/plugins/tweeple/faq/" target="_blank"><?php _e('See FAQ', 'tweeple'); ?></a> | <a href="https://vimeo.com/68603403" target="_blank"><?php _e('Watch Video', 'tweeple'); ?></a></p>
				</div>

				<div class="postbox inner-section">
					<h3><?php _e('OAuth Settings', 'tweeple'); ?></h3>
					<a href="#" class="button-secondary security-toggle show-values"><?php _e('Show Values', 'tweeple'); ?></a>
					<div class="col-wrap">
						<div class="col-left">
							<div class="col-inner control">
								<h4><?php _e('API key &mdash; <em>formerly "Consumer key"</em>', 'tweeple'); ?></h4>
								<input class="field" name="<?php echo $this->access_id; ?>[consumer_key]" value="<?php echo esc_attr( $settings['consumer_key'] ); ?>" type="password" />
								<input class="field hide" value="<?php echo esc_attr( $settings['consumer_key'] ); ?>" type="text" />
							</div>
						</div>
						<div class="col-right">
							<div class="col-inner control">
								<h4><?php _e('API secret &mdash; <em>formerly "Consumer secret"</em>', 'tweeple'); ?></h4>
								<input class="field" name="<?php echo $this->access_id; ?>[consumer_secret]" value="<?php echo esc_attr( $settings['consumer_secret'] ); ?>" type="password" />
								<input class="field hide" value="<?php echo esc_attr( $settings['consumer_secret'] ); ?>" type="text" />
							</div>
						</div>
					</div>
				</div><!-- .postbox (end) -->

				<div class="postbox inner-section">
					<h3><?php _e('Access Token', 'tweeple'); ?></h3>
					<a href="#" class="button-secondary security-toggle show-values"><?php _e('Show Values', 'tweeple'); ?></a>
					<div class="col-wrap">
						<div class="col-left">
							<div class="col-inner control">
								<h4><?php _e('Access token', 'tweeple'); ?></h4>
								<input class="field" name="<?php echo $this->access_id; ?>[user_token]" value="<?php echo esc_attr( $settings['user_token'] ); ?>" type="password" />
								<input class="field hide" value="<?php echo esc_attr( $settings['user_token'] ); ?>" type="text" />
							</div>
						</div>
						<div class="col-right">
							<div class="col-inner control">
								<h4><?php _e('Access secret', 'tweeple'); ?></h4>
								<input class="field" name="<?php echo $this->access_id; ?>[user_secret]" value="<?php echo esc_attr( $settings['user_secret'] ); ?>" type="password" />
								<input class="field hide" value="<?php echo esc_attr( $settings['user_secret'] ); ?>" type="text" />
							</div>
						</div>
					</div>
				</div><!-- .postbox (end) -->

				<div class="options-submit">
					<input type="submit" class="button-primary" value="<?php _e( 'Save Options', 'tweeple' ); ?>" />
					<input type="submit" class="clear-button button-secondary" value="<?php _e( 'Clear Options', 'tweeple' ); ?>" />
				</div><!-- .options-submit (end) -->

			</div><!-- .metabox-holder (end) -->

		</form>
		<?php
	}

	/*--------------------------------------------*/
	/* Settings API
	/*--------------------------------------------*/

	/**
	 * Register settings with WP
	 *
	 * @since 0.1.0
	 */
	function settings() {

		// Authorization settings
		$this->access_id = apply_filters( 'tweeple_access_id', 'tweeple_access' );
		register_setting( $this->access_id, $this->access_id, array( $this, 'validate_access' ) );

	}

	/**
	 * Settings sanitization
	 *
	 * @since 0.1.0
	 */
	function validate_access( $input ) {

		// Dump Twitter feed caches
		if ( ! $this->sanitized ) {

			$tweeple = Tweeple::get_instance();
			$feeds = $tweeple->get_feeds();

			foreach( $feeds as $key => $value )
				delete_transient( 'tweeple_'.$key );

		}

		// Clear options
		if ( isset( $input['clear'] ) ) {

			// Avoid duplicates
			if ( ! $this->sanitized ) {
				add_settings_error( $this->access_id, 'save_options', __( 'Options cleared.', 'tweeple' ), 'error fade' );
			}

			return null;
		}

		// Sanitize
		foreach( $input as $key => $value ) {
			$clean[$key] = wp_kses( $value, array() );
		}

		// Add success message, Avoid duplicates
		if ( ! $this->sanitized ) {
			add_settings_error( $this->access_id, 'save_options', __( 'Options saved.', 'tweeple' ), 'updated fade' );
		}

		// Check for future duplicate passes.
		$this->sanitized = true;

		return $clean;
	}

	/**
	 * Get saved settings for options form.
	 *
	 * @since 0.1.0
	 */
	function get_settings( $type ) {

		$settings = array();

		switch( $type ) {

			case 'access' :
				$option = get_option( $this->access_id );
				$settings['consumer_key'] = isset( $option['consumer_key'] ) ? $option['consumer_key'] : '';
				$settings['consumer_secret'] = isset( $option['consumer_secret'] ) ? $option['consumer_secret'] : '';
				$settings['user_token'] = isset( $option['user_token'] ) ? $option['user_token'] : '';
				$settings['user_secret'] = isset( $option['user_secret'] ) ? $option['user_secret'] : '';
				break;

		}

		return $settings;
	}
}