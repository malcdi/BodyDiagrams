class window.EventManager
  constructor:()->

  logEvent:(target, action)->
    $.ajax(
      type: "POST"
      url: "logEvent"
      data:
        targetName: target
        actionName: action
    )

  setup:(eventTarget, selection, host, arg)->
    _ = this
    switch eventTarget
      when 'newFrameButton'
        selection.on('click', ()-> 
            _.logEvent(eventTarget, 'click') #LOG
            host.addNew()
          )
          .on('mouseover', ()-> d3.select(this).attr('class', "#{arg} mouseover"))
          .on('mouseout', ()-> d3.select(this).attr('class', arg))

      when 'frame'
        selection.on('mouseover',()->
          className = d3.select(this).attr("class")
          d3.select(this).attr('class', "#{className} mouseover")
        )
        .on('mouseout',()->
          className = d3.select(this).attr("class")
          d3.select(this).attr('class', className.replace(' mouseover', ''))
        )
        .on('click',()->
          _.logEvent(eventTarget, 'click') #LOG
          index = d3.select(this).attr('frame_id')
          host.highlightWindow(+index)
          host.svg = d3.select(this)
          window.triggerEvent(
            {type:'frameChanged', message: index}
          )
        )

      when 'svgCanvas'
        _ = this
        selection.on("mousewheel", host.getEventHandler('mousewheel'))
          .on("mousedown", host.getEventHandler('mousedown'))
          .on("mousemove", host.getEventHandler('mousemove'))
          .on("click", host.getEventHandler('click'))

      when 'severityPropIcon'
        selection.on('click', ()-> 
          selected = $(this.parentElement).find(".tag-selected")
          selected.toggleClass("tag-selected")
          $(this).toggleClass("tag-selected")
        )

      when 'summary'
        selection.on('click', ()->
          _.logEvent(eventTarget, 'click') #LOG
          frameGroup = d3.select(this).attr('frame')
          sub = d3.select(this).attr('sub')
          host.canvasState.highlightFrame(+frameGroup, sub)
        )

      when 'toolbox'
        selection.on("click", -> 
          _.logEvent("toolbox_"+this.id, 'click') #LOG
          host.updateCurrent(false)
          host.currentMode = host.Modes[this.id]
          window.bigBro.cvState.setMode this.id
          host.updateCurrent(true))

      when 'toolbox_undo'
        selection.on("click", ->  
          _.logEvent(eventTarget, 'click') #LOG
          window.triggerEvent({type:'last_undo_click'})
        )
        .on("mouseover", ->  
          window.triggerEvent({type:'last_undo_mouseover'})
        )
        .on("mouseout", -> 
          window.triggerEvent({type:'last_undo_mouseout'})
        )

      when 'popup_done'
        selection.on("click",->
          _.logEvent(eventTarget, 'click') #LOG
          window.bigBro.cvState.deHighlightFrame()
        )

      when 'popup_delete'
        selection.on("click",->
          _.logEvent(eventTarget, 'click') #LOG
          if host.isPoppupOpen()
            index = host.openPopupIndex()
            host.closePopup()
            deletedTag = window.bigBro.cvState.deleteTag(index.frame, index.sub)
            window.bigBro.historyManager.deleteTag deletedTag
        )
        
      when 'rotate'
        selection.on("click", -> 
          _.logEvent(eventTarget, this.id) #LOG
          host.rotate(this.id)
        )

      when 'move_compass'
        selection.on("click", ->
          _.logEvent(eventTarget, @id) #LOG
          switch @id
            when "pan_left"
              window.bigBro.cvState.setZoomPan -host.moveFactor, 0, 0
            when "pan_right"
              window.bigBro.cvState.setZoomPan host.moveFactor, 0, 0
            when "pan_up"
              window.bigBro.cvState.setZoomPan 0, -host.moveFactor, 0
            when "pan_down"
              window.bigBro.cvState.setZoomPan 0, host.moveFactor, 0
        )

      when 'zoom_button'
        selection.on("click", ->
          _.logEvent(eventTarget, @id) #LOG
          zoomDirection = (if @id=="zoom_in" then 1 else -1)
          zoomMaxedCheck = (if @id=="zoom_in" then (parseInt(arg.style.top) > 0) else (parseInt(arg.style.top) < 137))
          if zoomMaxedCheck
            zoomOK = window.bigBro.cvState.setZoomPan 0, 0, zoomDirection*host.zoomFactor
            if zoomOK
              newY = parseInt(arg.style.top) - zoomDirection*host.sliderFactor*host.zoomFactor
              newY = Math.max(Math.min(137, newY), 0)
              arg.style.top = newY + "px"
        )            
      when 'zoom_slider'
        offsetTop = 245
        selection.on('mousedown', () ->
          _.logEvent(eventTarget, 'click') #LOG
          d3.event.preventDefault()
          oldY = parseInt(arg.style.top)
          newY = (d3.event.pageY - offsetTop)
          zoomOK = window.bigBro.cvState.setZoomPan 0, 0, (oldY - newY)*host.sliderFactor*host.zoomFactor/137
          if zoomOK
            arg.style.top = Math.max(Math.min(137, newY), 0) + "px"
            host.dragStart = true
        )
        .on('mousemove', () ->
          d3.event.preventDefault()
          if host.dragStart
            newY = (d3.event.pageY - offsetTop)
            newY = Math.max(Math.min(137, newY), 0)
            lastY = parseInt(arg.style.top)
            zoomOK = window.bigBro.cvState.setZoomPan 0, 0, (lastY - newY)*host.sliderFactor*host.zoomFactor/137
            if zoomOK
              arg.style.top = newY + "px"
        )
        .on('mouseup', ()-> host.dragStart = false)