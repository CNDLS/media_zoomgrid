window.unpack = (obj) ->
	return "undefined" unless (obj?)
		
	report = new Array()
	for key,value of obj
		if (value instanceof Function)
			report.push(key+":"+unpack(value))
		else
			if key != undefined
				report.push(key+":"+value)

	return report.join("\t")


class window.Grid
	@anim_duration = 250
	@anim_cmd = { duration: Grid.anim_duration, queue: false, easing: "linear" }
	
	@info_card_margin = 20
	@create_info_card = (info, grid_member) =>
		div = document.createElement("div")
		info_card = $(div).html(info)
			.addClass("info")
			.css('margin', @info_card_margin)
			.width(grid_member.content_width() - (2 * @info_card_margin))
			.height(grid_member.content_height() - (2 * @info_card_margin))
			.addClass(grid_member.constructor.name.toLowerCase())
		return info_card
		
	
	constructor: (@table) ->
		# we get our columns, rows, and cells from the elements that were rendered for them.
		@columns = $("th.col", @table)
		@rows = $("td.row", @table)
		@cells = $("td.cell", @table)
		@reset_btn = $("th#x", @table)
		
		@cell_color = "#222222"
		@selected_row_color = "#873220"
		@selected_column_color = "#9a1000"
		@selected_cell_color = "#cc877f"
		
		@info_card = null
		
		
		if @cells.length != (@columns.length * @rows.length)
			alert("Warning: "+@cells.length+" cells for "+@columns.length+" columns and "+@rows.length+" rows.")
			return
			
		# instantiate objects for our columns, rows, and cells
		@columns.each (index, column) =>
			new GridColumn(column, this, index)
			
		@rows.each (index, row) =>
			new GridRow(row, this, index)
			
		@cells.each (index, cell) =>
			new GridCell(cell, this, index)
			
		@reset_btn.each (index, btn) =>
			new ResetBtn(btn, this)
			
			
		# get column size targets.
		all_columns_width = @columns.width() * @columns.length
		@normal_column_width = all_columns_width / (1.0 * (@columns.length))
		@unselected_column_width = all_columns_width / (1.0 * (@columns.length + 1))
		@selected_column_width = 2 * @unselected_column_width
		if (@columns.length > 2)
			@unopened_column_width = all_columns_width / (1.0 * (@columns.length + 2))
			@opened_column_width = 3 * @selected_column_width
		else
			@unopened_column_width = @unselected_column_width
			@opened_column_width = @selected_column_width
		
	# get row size targets.
		all_rows_height = @rows.height() * @rows.length
		@normal_row_height = all_rows_height / (1.0 * (@rows.length))
		@unselected_row_height = all_rows_height / (1.0 * (@rows.length + 1))
		@selected_row_height = 2 * @unselected_row_height
		if (@rows.length > 2)
			@unopened_row_height = all_rows_height / (1.0 * (@rows.length + 2))
			@opened_row_height = 3 * @unopened_row_height
		else
			@unopened_row_height = @unselected_row_height
			@opened_row_height = @selected_row_height
		
		# size columns & rows to start.
		@columns.animate({ width:@normal_column_width }, 20, "linear")
		@rows.animate({ height:@normal_row_height }, 20, Grid.anim_easing)
		
		
	select_column: (column_element, grid_column) ->
		if (@columns.length == 1) then return
		@info_card.remove() unless (@info_card == null)
		# animate sizes
		@columns.not(column_element).animate({ width:@unselected_column_width }, Grid.anim_cmd)
		column_opening_cmd = $.extend({ complete:grid_column.show_content }, Grid.anim_cmd)
		$(column_element).animate({ width:@selected_column_width }, column_opening_cmd)
		@rows.nextAll().andSelf().animate({ height:@normal_row_height }, Grid.anim_cmd)
		# animate colors
		@rows.nextAll().animate({ backgroundColor:@cell_color }, Grid.anim_cmd)
		column_opening_cmd = $.extend({ complete:grid_column.show_content }, Grid.anim_cmd)
		grid_column.get_cells().animate({ backgroundColor:@selected_column_color }, Grid.anim_cmd)
		
		
	select_row: (row_element, grid_row) ->
		if (@rows.length == 1) then return
		@info_card.remove() unless (@info_card == null)
		# animate sizes
		@rows.nextAll().andSelf().not(row_element).animate({ height:@unselected_row_height }, Grid.anim_cmd)
		grid_row.get_cells().animate({ height:@selected_row_height }, Grid.anim_cmd)
		row_opening_cmd = $.extend({ complete:grid_row.show_content }, Grid.anim_cmd)
		$(row_element).animate({ height:@selected_row_height }, row_opening_cmd)
		@columns.animate({ width:@normal_column_width }, Grid.anim_cmd)
		# animate colors
		@rows.nextAll().animate({ backgroundColor:@cell_color }, Grid.anim_cmd)
		grid_row.get_cells().animate({ backgroundColor:@selected_row_color }, Grid.anim_cmd)
		
		
	open_cell: (cell_element, grid_cell) ->	
		if (@cells.length == 1) then return
		@info_card.remove() unless (@info_card == null)
		
		column_nbr = $(cell_element).data("column-nbr")
		row_nbr = $(cell_element).data("row-nbr")
		cell_column_element = @columns.get(column_nbr - 1)
		cell_row_element = @rows.get(row_nbr - 1)
		@columns.not(cell_column_element).animate({ width:@unopened_column_width }, Grid.anim_cmd)
		$(cell_column_element).animate({ width:@opened_column_width }, Grid.anim_cmd)
		@rows.nextAll().andSelf().not(cell_row_element).animate({ height:@unopened_row_height }, Grid.anim_cmd)
		$(cell_row_element).nextAll().andSelf().animate({ height:@opened_row_height }, Grid.anim_cmd)
		# animate colors
		@rows.nextAll().animate({ backgroundColor:@cell_color }, Grid.anim_cmd)
		$(cell_row_element).nextAll().animate({ backgroundColor:@selected_row_color }, Grid.anim_cmd)
		$(".cell[data-column-nbr="+$(cell_column_element).data("ordinal")+"]").animate({ backgroundColor:@selected_column_color }, Grid.anim_cmd)
		cell_opening_cmd = $.extend({ complete:grid_cell.show_content }, Grid.anim_cmd)
		$(cell_element).animate({ backgroundColor:"white" },  cell_opening_cmd)
		
		
	reset: ->	
		@info_card.remove() unless (@info_card == null)
		@cells.animate({ width:@normal_column_width, height:@normal_row_height }, Grid.anim_cmd)
		@columns.animate({ width:@normal_column_width }, Grid.anim_cmd)
		@rows.animate({ height:@normal_row_height }, Grid.anim_cmd)
		# animate colors
		@rows.nextAll().animate({ backgroundColor:@cell_color }, Grid.anim_cmd)
		@columns.each( (index, element) ->
			$(".cell[data-column-nbr="+$(element).data("ordinal")+"]").animate({ backgroundColor:@cell_color }, Grid.anim_cmd)
		)


# okay, right now there's not much here, but the Grid code should probably be refactored
# and some stuff put into these classes.
class GridColumn
	
	constructor: (@element, @grid, @index) ->
		@cells = @.get_cells()
		$(@element).click (e) =>
			@grid.select_column(@element, this)
			
	get_cells: ->
		return $(".cell[data-column-nbr="+$(@element).data("ordinal")+"]")
		
	show_content: =>
		@grid.info_card = Grid.create_info_card(columns_json[@index].fields.description, this)
		@grid.info_card.appendTo(@element)
		
	content_width: ->
		return @cells.width()
		
	content_height: ->
		return (@cells.height() * @cells.length)
		
	content_position: ->
		return @cells.eq(0).position()
			


class GridRow
	
	constructor: (@element, @grid, @index) ->
		@cells = @.get_cells()
		$(@element).click (e) =>
			@grid.select_row(@element, this)
			
	get_cells: ->
		return $(@element).nextAll()
			
	show_content: =>
		console.log rows_json
		@grid.info_card = Grid.create_info_card(rows_json[@index].fields.description, this)
		@grid.info_card.appendTo(@element)
		card_offset = @cells.eq(0).offset()
		card_margin = parseInt( @grid.info_card.css("margin"), 10)
		card_offset = { left: card_offset.left + card_margin, top: card_offset.top + card_margin }
		@grid.info_card.offset(card_offset)
		
	content_width: ->	
		return (@cells.width() * @cells.length)

	content_height: ->
		return @cells.height()
		
	content_position: ->
		cells_pos = @cells.eq(0).position()
		cells_pos.left = cells_pos.left + 200
		console.log cells_pos
		return cells_pos
		


class GridCell
	constructor: (@element, @grid, @index) ->
		$(@element).click (e) =>	
			@grid.info_card.remove() unless (@grid.info_card == null)
			@grid.open_cell(@element, this)
				
	show_content: =>
		# @grid.info_card = Grid.create_info_card("cell info", this)
		
			
class ResetBtn
	constructor: (@element, @grid) ->
		$(@element).click (e) =>
				@grid.reset()
	

################################################


$ ->
	grid = new Grid($("table#grid"))