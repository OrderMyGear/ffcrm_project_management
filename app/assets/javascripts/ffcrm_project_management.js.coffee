#= require './chosen.jquery.coffee'

(($) ->
  window.crm ||= {}

  crm.makeScopedAjaxChosen = ->
    $("select.ajax_chosen_1").each ->
      $(this).ajaxChosenScoped({
        url: $(this).data('url')     ,
        dataCallback: (data) ->
          if (val = $('#account_id').val()) && val != ''
            data['scope'] = "account_#{val}"
          data
        jsonTermKey: "auto_complete_query",
        minTermLength: 2},
        null,
        {allow_single_deselect: true, show_on_activate: true}
      )

  $(document).ready ->
    crm.makeScopedAjaxChosen()


  $(document).ajaxComplete ->
    crm.makeScopedAjaxChosen()

    $('#account_id').on 'change', (event) ->
      $('#project_contact_ids').val('').trigger('liszt:updated')
      $('#project_contact_ids_chzn input').trigger('auto_complete:search')


    #$('#project_contact_ids_chzn').on 'click', (event) ->
    #  $('#project_contact_ids_chzn input').trigger('auto_complete:search')


) jQuery


do ($ = jQuery) ->

  $.fn.ajaxChosenScoped = (settings = {}, callback, chosenOptions = {}) ->
    defaultOptions =
      minTermLength: 3
      afterTypeDelay: 500
      jsonTermKey: "term"
      keepTypingMsg: "Keep typing..."
      lookingForMsg: "Looking for"

    select = @
    chosenXhr = null
    options = $.extend {}, defaultOptions, $(select).data(), settings

    @chosen(if chosenOptions then chosenOptions else {})


    @each ->
      $(@).next('.chzn-container')
        .find(".search-field > input, .chzn-search > input")
        .bind 'keyup', ->

          untrimmed_val = $(@).val()
          val = $.trim $(@).val()

          msg = if val.length < options.minTermLength then options.keepTypingMsg else options.lookingForMsg + " '#{val}'"
          select.next('.chzn-container').find('.no-results').text(msg)

          return false if val is $(@).data('prevVal')

          $(@).data('prevVal', val)

          clearTimeout(@timer) if @timer

          return false if val.length < options.minTermLength

          field = $(@)

          options.data = {} unless options.data?
          options.data[options.jsonTermKey] = val
          options.data = options.dataCallback(options.data) if options.dataCallback?

          success = options.success
          options.success = (data) ->

            return unless data?

            selected_values = []
            select.find('option').each ->
              if not $(@).is(":selected")
                $(@).remove()
              else
                selected_values.push $(@).val() + "-" + $(@).text()
            select.find('optgroup:empty').each ->
              $(@).remove()

            items = if callback? then callback(data, field) else data

            nbItems = 0

            $.each items, (i, element) ->
              nbItems++

              if element.group
                group = select.find("optgroup[label='#{element.text}']")
                group = $("<optgroup />") unless group.size()

                group.attr('label', element.text)
                  .appendTo(select)
                $.each element.items, (i, element) ->
                  if typeof element == "string"
                    value = i;
                    text = element;
                  else
                    value = element.value;
                    text = element.text;
                  if $.inArray(value + "-" + text, selected_values) == -1
                    $("<option />")
                      .attr('value', value)
                      .html(text)
                      .appendTo(group)
              else
                if typeof element == "string"
                  value = i;
                  text = element;
                else
                  value = element.value;
                  text = element.text;
                if $.inArray(value + "-" + text, selected_values) == -1
                  $("<option />")
                    .attr('value', value)
                    .html(text)
                    .appendTo(select)

            if nbItems
              select.trigger("liszt:updated")
            else
              select.data().chosen.no_results_clear()
              select.data().chosen.no_results field.val()


            settings.success(data) if settings.success?


            field.val(untrimmed_val)

          @timer = setTimeout ->
            chosenXhr.abort() if chosenXhr
            chosenXhr = $.ajax(options)
          , options.afterTypeDelay


    @each ->
      $(@).next('.chzn-container')
        .find(".search-field > input, .chzn-search > input")
        .bind 'auto_complete:search', ->

          val = ''
          $(@).data('prevVal', val)

          clearTimeout(@timer) if @timer

          field = $(@)

          options.data = {} unless options.data?
          options.data[options.jsonTermKey] = val
          options.data = options.dataCallback(options.data) if options.dataCallback?

          success = options.success
          options.success = (data) ->

            return unless data?

            selected_values = []
            select.find('option').each ->
              if not $(@).is(":selected")
                $(@).remove()
              else
                selected_values.push $(@).val() + "-" + $(@).text()
            select.find('optgroup:empty').each ->
              $(@).remove()

            items = if callback? then callback(data, field) else data

            nbItems = 0

            $.each items, (i, element) ->
              nbItems++

              if element.group
                group = select.find("optgroup[label='#{element.text}']")
                group = $("<optgroup />") unless group.size()

                group.attr('label', element.text)
                  .appendTo(select)
                $.each element.items, (i, element) ->
                  if typeof element == "string"
                    value = i;
                    text = element;
                  else
                    value = element.value;
                    text = element.text;
                  if $.inArray(value + "-" + text, selected_values) == -1
                    $("<option />")
                      .attr('value', value)
                      .html(text)
                      .appendTo(group)
              else
                if typeof element == "string"
                  value = i;
                  text = element;
                else
                  value = element.value;
                  text = element.text;
                if $.inArray(value + "-" + text, selected_values) == -1
                  $("<option />")
                    .attr('value', value)
                    .html(text)
                    .appendTo(select)

            select.trigger("liszt:updated")

            settings.success(data) if settings.success?


          @timer = setTimeout ->
            chosenXhr.abort() if chosenXhr
            chosenXhr = $.ajax(options)
          , options.afterTypeDelay
