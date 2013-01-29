window.attachEventListeners= ()->
  $(window).on('updateProperty', (e)->
    @bigBro.cvState.uploadTagProperties(e.message.properties,e.message.index)
    )

  $(window).on('highlighted', (e)->
    @bigBro.propToolbox.activatePropertyControls(e.message.highlight, 
      e.message.box, e.message.properties, e.message.index)
    )

  $(window).on('newTag', (e)->
    @bigBro.historyManager.addNewTag(e.message.points)
    )

  $(window).on('mousedown', (e)->
    possibleParents = ['#toolbox_property', '.ui-multiselect-menu']
    if @bigBro.propToolbox.isPoppupOpen()
      for parent in possibleParents
        return if $(parent).has(e.target).length!=0 
      @bigBro.cvState.deHighlightFrame()
    )

  $(window).on('tagMoving', (e)->
    if @bigBro.propToolbox.isPoppupOpen() 
      @bigBro.propToolbox.boxMove(e.message.box)
    )
  $(window).on('tagMovingDone', (e)->
    @bigBro.historyManager.moveThumbnailTag(e.message.frameIndex, e.message.subIndex, e.message.dataPoints)
    )

  $(window).on('last_undo_mouseover', (e)->
    @bigBro.cvState.showNextUndo()
    )

  $(window).on('last_undo_click', (e)->
    @bigBro.cvState.deleteTag()
    )

  $(window).on('last_undo_mouseout', (e)->
    @bigBro.cvState.hideNextUndo()
    )
  
  $(window).on('rotated', (e)->
    @bigBro.cvState.setView e.message

    #rotate the view in historymanager
    @bigBro.historyManager.setView e.message
    )

  $(window).on('frameChanged', (e)->
    @bigBro.cvState.changeFrame +e.message
    )
  
    