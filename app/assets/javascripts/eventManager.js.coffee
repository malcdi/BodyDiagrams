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
          window.bigBro.cvState.deHighlightFrame()
        )

      when 'popup_delete'
        selection.on("click",->
          host.closePopup()
          deletedTag = window.bigBro.cvState.deleteTag()
          window.bigBro.historyManager.deleteTag deletedTag
        )
        
      when 'rotate'
        selection.on("click", -> 
          _.logEvent(eventTarget, this.id) #LOG
          host.rotate(this.id)
        )

      when 'move_compass'
        selection.on("click", ->
          _.logEvent(eventTarget, @title) #LOG
          switch @title
            when "Pan left"
              window.bigBro.cvState.setZoomPan -host.moveFactor, 0, 0
            when "Pan right"
              window.bigBro.cvState.setZoomPan host.moveFactor, 0, 0
            when "Pan up"
              window.bigBro.cvState.setZoomPan 0, -host.moveFactor, 0
            when "Pan down"
              window.bigBro.cvState.setZoomPan 0, host.moveFactor, 0
        )

      when 'zoom_button'
        selection.on("click", ->
          _.logEvent(eventTarget, @title) #LOG
          zoomDirection = (if @title=="Zoom In" then 1 else -1)
          zoomMaxedCheck = (if @title=="Zoom In" then (parseInt(arg.style.top) > 0) else (parseInt(arg.style.top) < 137))
          if zoomMaxedCheck
            zoomOK = window.bigBro.cvState.setZoomPan 0, 0, zoomDirection*host.zoomFactor
            if zoomOK
              newY = parseInt(arg.style.top) - zoomDirection*15*host.zoomFactor
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
          zoomOK = window.bigBro.cvState.setZoomPan 0, 0, (oldY - newY)*15*host.zoomFactor/137
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
            zoomOK = window.bigBro.cvState.setZoomPan 0, 0, (lastY - newY)*15*host.zoomFactor/137
            if zoomOK
              arg.style.top = newY + "px"
        )
        .on('mouseup', ()-> host.dragStart = false)