jQuery(document).ready(function($){

	/**
	 * Fade out notices
	 */
	$('#tweeple .fade').delay(2000).fadeOut(1000);

	/**
	 * Setup Feed configuration form.
	 */
	var form = $('#feed-config');

	form.find('.feed-type-wrap select').change(function(){
		var new_type = $(this).val();
		form.find('.toggle').hide()
		form.find('.toggle-'+new_type).show();

	});

	/**
	 * Delete feed.
	 */
	$('#tweeple #tweeple-feeds-manage .trash a').click(function(){

		var post_id = $(this).attr('href'),
			post_id = post_id.replace('#', ''),
			r = confirm(tweeple.delete_msg);

		if( r == true ) {
			$(this)
			.closest('#tweeple-feeds-manage')
			.prepend('<input name="delete-post" value="'+post_id+'" type="hidden" />')
			.submit();
		}

		return false;

	});

	/**
	 * Authentication form security.
	 */
	$('#tweeple-authentication .field').change(function(){
		var val = $(this).val();
		$(this).closest('.control').find('.field').val(val);
	});

	$('#tweeple-authentication .security-toggle').click(function(){

		var el = $(this);

		if( el.hasClass('show-values') ) {

			// Hide password field, and show text field.
			el.closest('.postbox').find('.field[type="password"]').hide();
			el.closest('.postbox').find('.field[type="text"]').show();

			// Convert to "Hide Values" button.
			el.removeClass('show-values');
			el.addClass('hide-values');
			el.text(tweeple.hide_msg);

		} else {

			// Hide text field, and show password field.
			el.closest('.postbox').find('.field[type="text"]').hide();
			el.closest('.postbox').find('.field[type="password"]').show();

			// Convert to "Show Values" button.
			el.removeClass('hide-values');
			el.addClass('show-values');
			el.text(tweeple.show_msg);
		}

	});

	/**
	 * Clear authentication options.
	 */
	$('#tweeple-authentication .clear-button').click(function(){

		var form = $(this).closest('form'),
			r = confirm(tweeple.clear_msg);

		if( r == true ) {
	    	form.append('<input type="hidden" name="'+tweeple.access_id+'[clear]" value="true" />');
	    	form.submit();
	    }

	    return false;
	});

});