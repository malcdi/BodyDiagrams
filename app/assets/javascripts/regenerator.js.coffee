window.regenerate = ()->
  _ = window.bigBro
  dataArr = window.allTags
  
  frameIndex = 0
  for frameGroup in dataArr
    if frameIndex>0
      #generate a frame
      _.historyManager.addNew()
    for tag in frameGroup
      #create tag elem
      tagElem = null
      if tag.type is "region"
        tagElem = new RegionElem("#F89393", tag.view_side)
        tagElem.setBound(tag.data)
      else
        tagElem = new FreehandElem("#F89393", tag.view_side)
        tagElem.setAllPoints(tag.data)
        tagElem.filled = tag.fill

      subIndex = _.cvState.addTagElem(tagElem, frameIndex)
      tagElem.setIndex(frameIndex, subIndex)

      #create the element in svg
      svgElem = _.cvState.createInSvg(frameIndex, tagElem.type)

      #draw in canvas state
      _.cvState.drawInSvg(svgElem, tagElem)
      #draw in history manager
      tagData = if tag.type is "region" then tagElem.getRectBound() else tagElem.points
      _.historyManager.addNewTag({
        frame:frameIndex
        sub:subIndex
        type:tagElem.type
        data:tagData})
      console.log tag.properties
      #set property values
      tagElem.saveProperties tag.properties

      _.cvState.highlightFrame frameIndex, subIndex

      #sum = _.cvState.summaryManager.getSummary(frameIndex, subIndex)
      _.cvState.summaryManager.updateSummary(frameIndex, subIndex, tag.properties)
      _.cvState.deHighlightFrame

      subIndex++
    frameIndex++