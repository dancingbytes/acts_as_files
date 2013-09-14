# encoding: utf-8
class CreateMultimedia < ActiveRecord::Migration

  def change

    create_table :multimedia do |t|

      t.integer     :source_id,     default: 0

      t.string      :ext,           default: '',   limit: 10

      t.string      :mark,          default: '',   limit: 255

      t.integer     :width,         default: 0

      t.integer     :height,        default: 0

      # Имя класса связанного объекта
      t.string      :context_type,  default: '',   limit: 255

      # Идентификатор экземплряра связанного объекта
      t.integer     :context_id,    default: 0

      # Поле/метод объекта для уточнения контекста связи
      t.string      :context_field, default: '',   limit: 255

      # Mime-type
      t.string      :mime_type,     default: '',   limit: 255

      t.timestamp   :updated_at

      t.integer     :position

      t.integer     :size,          default: 0

      t.string      :name,          default: '',   limit: 255

    end # create_table

    add_index :multimedia,  :mime_type, name: "mime_type_indx", unique: false

    # mix1
    add_index :multimedia, [
      :mark, :source_id, :context_type, :context_id, :context_field
    ],
    name: "mix1_indx",
    unique: false

    # mix2
    add_index :multimedia, [
      :width, :height, :context_type, :context_id, :context_field
    ],
    name: "mix2_indx",
    unique: false

    add_index :multimedia, :ext,         name: "ext_indx",        unique: false
    add_index :multimedia, :updated_at,  name: "updated_at_indx", unique: false

  end # change

end # CreateMultimedia
