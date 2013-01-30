window.triggerEvent= (e)->
  switch e.type
    when 'updateProperty'
      @bigBro.cvState.uploadTagProperties(e.message.properties,e.message.index)
      
    when 'highlighted'
      @bigBro.propToolbox.activatePropertyControls(e.message.highlight, 
        e.message.box, e.message.properties, e.message.index)
      
    when 'newTag'
      @bigBro.historyManager.addNewTag(e.message)
      
    when 'mousedown'
      possibleParents = ['#toolbox_property', '.ui-multiselect-menu']
      if @bigBro.propToolbox.isPoppupOpen()
        for parent in possibleParents
          return if $(parent).has(e.target).length!=0 
        @bigBro.cvState.deHighlightFrame()
      
    when 'tagMoving'
      if @bigBro.propToolbox.isPoppupOpen() 
        @bigBro.propToolbox.boxMove(e.message.box)
  
    when 'tagMovingDone'
      @bigBro.historyManager.moveThumbnailTag(e.message.frameIndex, e.message.subIndex, e.message.dataPoints)
      @eventManager.logEvent('tag', 'moved')
      
    when 'imageMovingDone'
      @eventManager.logEvent('image', 'panned')
      
    when 'last_undo_mouseover'
      @bigBro.cvState.showNextUndo()
      
    when 'last_undo_click'
      @bigBro.cvState.deleteTag()
      
    when 'last_undo_mouseout'
      @bigBro.cvState.hideNextUndo()
    
    when 'rotated'
      @bigBro.cvState.setView e.message

      #rotate the view in historymanager
      @bigBro.historyManager.setView e.message
      
    when 'frameChanged'
      @bigBro.cvState.changeFrame +e.message

  
    