require 'sketchup.rb'

module MyLineCopyPlugin
  def self.copy_lines_along_axis
    dialog = UI::WebDialog.new("沿指定轴递增复制线段", true, "MyLineCopyPlugin", 400, 300, 200, 200, true)

    html = <<-HTML
      <html>
      <head>
        <meta charset="UTF-8">
        <style>
          body {
            background-color: #e8f5e9; /* 绿色调背景 */
            font-family: Arial, sans-serif;
          }
          table {
            width: 100%;
            padding: 10px;
          }
          td {
            padding: 5px;
          }
          input, select, button {
            width: 100%;
            padding: 5px;
          }
          button {
            background-color: #4caf50; /* 绿色调按钮 */
            color: white;
            border: none;
            cursor: pointer;
          }
          button:hover {
            background-color: #81c784;
          }
        </style>
        <script>
          function updateNumCopies() {
            var total_distance_mm = parseFloat(document.getElementById('total_distance').value);
            if (isNaN(total_distance_mm) || total_distance_mm <= 0) {
              document.getElementById('num_copies').value = 0;
              return;
            }
            var unit_length_mm = 110.0;
            var num_copies = Math.floor(total_distance_mm / unit_length_mm);
            document.getElementById('num_copies').value = num_copies;
          }
        </script>
      </head>
      <body>
        <table>
          <tr>
            <td>复制数量:</td>
            <td><input type="number" id="num_copies" value="0"></td>
          </tr>
          <tr>
            <td>总距离 (mm):</td>
            <td><input type="number" id="total_distance" value="0" onkeyup="updateNumCopies()"></td>
          </tr>
          <tr>
            <td>轴:</td>
            <td>
              <select id="axis">
                <option value="X">X</option>
                <option value="Y">Y</option>
                <option value="Z">Z</option>
              </select>
            </td>
          </tr>
        </table>
        <button onclick="window.location = 'skp:submit@' + document.getElementById('num_copies').value + ',' + document.getElementById('total_distance').value + ',' + document.getElementById('axis').value">确定</button>
      </body>
      </html>
    HTML

    dialog.set_html(html)

    dialog.add_action_callback("submit") do |_, params|
      num_copies, total_distance, axis = params.split(',')
      num_copies = num_copies.to_i
      total_distance = total_distance.to_f.mm

      model = Sketchup.active_model
      entities = model.active_entities
      selection = model.selection

      lines = selection.grep(Sketchup::Edge)

      if lines.empty?
        UI.messagebox("请先选择至少一条线段。")
        return
      end

      model.start_operation("沿指定轴递增复制线段", true)
      increment_distance = total_distance / num_copies

      (1..num_copies).each do |i|
        distance = i * increment_distance
        case axis.upcase
        when 'X'
        vector = Geom::Vector3d.new(distance, 0, 0)
        when 'Y'
        vector = Geom::Vector3d.new(0, distance, 0)
        when 'Z'
        vector = Geom::Vector3d.new(0, 0, distance)
        else
        UI.messagebox("无效的轴，请输入 X, Y 或 Z。")
        return
        end
        transformation = Geom::Transformation.translation(vector)
        lines.each do |line|
          start_point = line.start.position
          end_point = line.end.position
    
          new_start_point = start_point.transform(transformation)
          new_end_point = end_point.transform(transformation)
          entities.add_line(new_start_point, new_end_point)
        end
      end
    
      model.commit_operation
      dialog.close
    end
    
    dialog.show
  end

  file_name = "copy_lines_along_axis.rb"
  
  unless file_loaded?(file_name)
  menu = UI.menu('Plugins')
  menu.add_item('沿指定轴递增复制线段') { copy_lines_along_axis }
  file_loaded(file_name)
  end
  end    
