<?php
/**
 * Widget to display Twitter feed.
 *
 * @since 0.1.0
 */
class Tweeple_Feed_Widget extends WP_Widget {

	/**
	 * Constructor
	 *
	 * @since 0.1.0
	 */
	function __construct() {
		$widget_ops = array(
			'classname' 	=> 'tweeple-feed-widget',
			'description' 	=> 'Display a Twitter feed setup from Tools > Tweeple.'
		);
        $this->WP_Widget( 'tweeple_feed_widget', 'Tweeple Twitter Feed', $widget_ops );
	}

	/**
	 * Display Widget
	 *
	 * @since 0.1.0
	 */
	function widget( $args, $instance ) {
		extract( $args );

		// Check for missing feed id.
		if ( empty( $instance['feed_id'] ) ) {
			echo __( 'No Twitter feed ID given.', 'tweeple' );
			return;
		}

		// Get new Twitter feed, or cached result
		$feed = tweeple_get_feed( $instance['feed_id'] );

		// Get Tweets
        $tweets = tweeple_get_tweets( $feed ); // @todo Could incorporate feed merging in the future here. tweeple_get_tweets( array( $feed1, $feed2, $feed3 ) )

		// Display widget
		echo $before_widget;

		$title = apply_filters( 'widget_title', $instance['title'] );
		if ( ! empty( $title ) )
			echo $before_title.$title.$after_title;

		echo '<div class="tweeple tweeple-feed tweeple-feed-widget">';
        echo '<div class="tweeple-inner">';

        if ( ! tweeple_error( $feed ) ) {

        	// We are a go! Display widget.
            do_action( 'tweeple_display_widget', $tweets, $feed['options'], $feed['info'] );

        } else {

			// Display error
            printf( '<p>%s</p>', tweeple_error( $feed ) );

        }

		echo '</div><!-- .tweeple-inner (end) -->';
		echo '</div><!-- .tweeple-feed-widget (end) -->';

		echo $after_widget;
	}

	/**
	 * Widget Options Form
	 *
	 * @since 0.1.0
	 */
	function form( $instance ) {

		// Get twitter feeds created by user
		$tweeple = Tweeple::get_instance();
		$feeds = $tweeple->get_feeds();

		// Set current values for form
		$current_title = isset( $instance['title'] ) ? esc_attr( $instance['title'] ) : '';
		$current_feed_id = isset( $instance['feed_id'] ) ? esc_attr( $instance['feed_id'] ) : '';
		?>
		<p>
			<label for="<?php echo $this->get_field_name( 'title' ); ?>"><?php _e( 'Title:', 'tweeple' ); ?></label>
			<input class="widefat" id="<?php echo $this->get_field_id( 'title' ); ?>" name="<?php echo $this->get_field_name( 'title' ); ?>" type="text" value="<?php echo esc_attr( $current_title ); ?>" />
		</p>
		<p>
			<label for="<?php echo $this->get_field_id('feed_id'); ?>"><?php _e( 'Twitter Feed:', 'tweeple' ); ?></label>
			<?php if ( count( $feeds ) > 0 ) : ?>
				<select class="widefat" id="<?php echo $this->get_field_id('feed_id'); ?>" name="<?php echo $this->get_field_name('feed_id'); ?>">
					<?php
					foreach( $feeds as $key => $value )
						printf('<option %s value="%s">%s</option>', selected( $key, $current_feed_id ), $key, $value );
					?>
				</select>
			<?php else : ?>
				<em><?php _e('You haven\'t created any Twitter feeds yet. Go to Tools > Tweeple to create one!', 'tweeple'); ?></em>
			<?php endif; ?>
		</p>
		<?php
	}

	/**
	 * Update Widget Settings
	 *
	 * @since 0.1.0
	 */
	function update( $new_instance, $old_instance ) {
		$instance = array();
		$instance['title'] = ( ! empty( $new_instance['title'] ) ) ? wp_kses( $new_instance['title'], array() ) : '';
		$instance['feed_id'] = ( ! empty( $new_instance['feed_id'] ) ) ? wp_kses(  $new_instance['feed_id'], array() ) : '';
		return $instance;
	}
}