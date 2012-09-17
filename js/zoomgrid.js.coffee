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
	@anim_cmd = { duration: Grid.anim_duration, queue: false }
	
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
		
		
		if @cells.length != (@columns.length * @rows.length)
			alert("Warning: "+@cells.length+" cells for "+@columns.length+" columns and "+@rows.length+" rows.")
			return
			
		# instantiate objects for our columns, rows, and cells
		@columns.each (index, column) =>
			new GridColumn(column, this)
			
		@rows.each (index, row) =>
			new GridRow(row, this)
			
		@cells.each (index, cell) =>
			new GridCell(cell, this)
			
		@reset_btn.each (index, btn) =>
			new ResetBtn(btn, this)
			
		# size grid columns to start.
		all_columns_width = @columns.width() * @columns.length
		@normal_column_width = all_columns_width / (1.0 * (@columns.length))
		@contracted_column_width = all_columns_width / (1.0 * (@columns.length + 1))
		@columns.animate({ width:@normal_column_width }, 20)
		
		# size grid rows to start.
		all_rows_height = @rows.height() * @rows.length
		@normal_row_height = all_rows_height / (1.0 * (@rows.length))
		@contracted_row_height = all_rows_height / (1.0 * (@rows.length + 1))
		@rows.animate({ height:@normal_row_height }, 20)
		
		
	expand_column: (column_element, grid_column) ->
		@columns.not(column_element).animate({ width:@contracted_column_width }, Grid.anim_cmd)
		column_opening_cmd = $.extend({ complete:grid_column.show_content }, Grid.anim_cmd)
		$(column_element).animate({ width:(2*@contracted_column_width) }, column_opening_cmd)
		@rows.nextAll().andSelf().animate({ height:@normal_row_height }, Grid.anim_cmd)
		# animate colors
		@rows.nextAll().animate({ backgroundColor:@cell_color }, Grid.anim_cmd)
		column_opening_cmd = $.extend({ complete:grid_column.show_content }, Grid.anim_cmd)
		grid_column.get_cells().animate({ backgroundColor:@selected_column_color }, Grid.anim_cmd)
		
		
	expand_row: (row_element, grid_row) ->
		# expand row. collapse other rows & columns, too, if nec.
		@rows.nextAll().andSelf().not(row_element).animate({ height:@contracted_row_height }, Grid.anim_cmd)
		grid_row.get_cells().animate({ height:(2*@contracted_row_height) }, Grid.anim_cmd)
		row_opening_cmd = $.extend({ complete:grid_row.show_content }, Grid.anim_cmd)
		$(row_element).animate({ height:(2*@contracted_row_height) }, row_opening_cmd)
		@columns.animate({ width:@normal_column_width }, Grid.anim_cmd)
		# animate colors
		@rows.nextAll().animate({ backgroundColor:@cell_color }, Grid.anim_cmd)
		grid_row.get_cells().animate({ backgroundColor:@selected_row_color }, Grid.anim_cmd)
		
		
	expand_cell: (cell_element, grid_cell) ->
		column_nbr = $(cell_element).data("column-nbr")
		row_nbr = $(cell_element).data("row-nbr")
		cell_column_element = @columns.get(column_nbr - 1)
		cell_row_element = @rows.get(row_nbr - 1)
		@columns.not(cell_column_element).animate({ width:@contracted_column_width }, Grid.anim_cmd)
		$(cell_column_element).animate({ width:(2*@contracted_column_width) }, Grid.anim_cmd)
		@rows.nextAll().andSelf().not(cell_row_element).animate({ height:@contracted_row_height }, Grid.anim_cmd)
		$(cell_row_element).nextAll().andSelf().animate({ height:(2*@contracted_row_height) }, Grid.anim_cmd)
		# animate colors
		@rows.nextAll().animate({ backgroundColor:@cell_color }, Grid.anim_cmd)
		$(cell_row_element).nextAll().animate({ backgroundColor:@selected_row_color }, Grid.anim_cmd)
		$(".cell[data-column-nbr="+$(cell_column_element).data("ordinal")+"]").animate({ backgroundColor:@selected_column_color }, Grid.anim_cmd)
		cell_opening_cmd = $.extend({ complete:grid_cell.show_content }, Grid.anim_cmd)
		$(cell_element).animate({ backgroundColor:"white" },  cell_opening_cmd)
		
		
	reset: ->
		@columns.animate({ width:@normal_column_width }, Grid.anim_cmd)
		@rows.nextAll().andSelf().animate({ height:@normal_row_height }, Grid.anim_cmd)
		# animate colors
		@rows.nextAll().animate({ backgroundColor:@cell_color }, Grid.anim_cmd)
		@columns.each( (index, element) ->
			$(".cell[data-column-nbr="+$(element).data("ordinal")+"]").animate({ backgroundColor:@cell_color }, Grid.anim_cmd)
		)


# okay, right now there's not much here, but the Grid code should probably be refactored
# and some stuff put into these classes.
class GridColumn
	constructor: (@element, @grid) ->
		$(@element).click (e) =>
			@grid.expand_column(@element, this)
			
	get_cells: ->
		return $(".cell[data-column-nbr="+$(@element).data("ordinal")+"]")
		
	show_content: ->
		alert("column content")
			

class GridRow
	constructor: (@element, @grid) ->
		$(@element).click (e) =>
			@grid.expand_row(@element, this)
			
	get_cells: ->
		return $(@element).nextAll()
			
	show_content: ->
		alert("row content")
			

class GridCell
	constructor: (@element, @grid) ->
		$(@element).click (e) =>	
				@grid.expand_cell(@element, this)
				
	show_content: ->
		alert("content")
		
			
class ResetBtn
	constructor: (@element, @grid) ->
		$(@element).click (e) =>	
				@grid.reset()
	

################################################


$ ->
	grid = new Grid($("table#grid"))