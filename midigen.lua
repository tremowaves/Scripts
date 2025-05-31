--[[
Name: MIDI Melody Generator & Editor
Author: Reaper Script Maker
Description: Read, edit, and generate MIDI melodies with drag-and-drop functionality
]]

local window_w, window_h = 600, 500
local scroll_y = 0
local selected_note = -1
local edit_mode = false
local new_pitch = 60
local new_velocity = 100
local new_start = 0
local new_length = 120

function get_selected_midi_take()
    local item = reaper.GetSelectedMediaItem(0, 0)
    if not item then return nil end
    local take = reaper.GetActiveTake(item)
    if take and reaper.TakeIsMIDI(take) then
        return take
    end
    return nil
end

function get_notes(take)
    local notes = {}
    local _, note_count, _, _ = reaper.MIDI_CountEvts(take)
    for i = 0, note_count-1 do
        local _, sel, mute, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
        table.insert(notes, {
            index = i,
            startppq = startppq,
            endppq = endppq,
            pitch = pitch,
            vel = vel,
            chan = chan,
            sel = sel,
            mute = mute,
            length = endppq - startppq
        })
    end
    return notes
end

function insert_random_melody(take)
    reaper.MIDI_SelectAll(take, true)
    local _, note_count, _, _ = reaper.MIDI_CountEvts(take)
    for i = note_count-1, 0, -1 do
        reaper.MIDI_DeleteNote(take, i)
    end
    
    local ppq = 0
    local scales = {60, 62, 64, 65, 67, 69, 71, 72} -- C major scale
    for i = 1, 8 do
        local pitch = scales[math.random(1, #scales)]
        local vel = math.random(80, 120)
        local len = math.random(60, 240)
        reaper.MIDI_InsertNote(take, false, false, ppq, ppq+len, 0, pitch, vel, false)
        ppq = ppq + len + math.random(0, 60)
    end
    reaper.MIDI_Sort(take)
end

function create_new_midi_item()
    local track = reaper.GetSelectedTrack(0, 0)
    if not track then
        track = reaper.GetTrack(0, 0)
    end
    if not track then return nil end
    
    local cursor_pos = reaper.GetCursorPosition()
    local item = reaper.CreateNewMIDIItemInProj(track, cursor_pos, cursor_pos + 4, false)
    local take = reaper.GetActiveTake(item)
    
    if take then
        insert_random_melody(take)
        reaper.UpdateItemInProject(item)
    end
    
    return item
end

function edit_note(take, note_index, pitch, velocity, start_ppq, length)
    local end_ppq = start_ppq + length
    reaper.MIDI_SetNote(take, note_index, nil, nil, start_ppq, end_ppq, nil, pitch, velocity, false)
end

function draw_button(x, y, w, h, text, active)
    if active then
        gfx.set(0.3, 0.7, 0.3, 1)
    else
        gfx.set(0.2, 0.5, 0.2, 1)
    end
    gfx.rect(x, y, w, h, 1)
    gfx.set(1, 1, 1, 1)
    gfx.x, gfx.y = x + 5, y + h/2 - 6
    gfx.drawstr(text)
    
    return gfx.mouse_x >= x and gfx.mouse_x <= x+w and gfx.mouse_y >= y and gfx.mouse_y <= y+h
end

function draw_slider(x, y, w, label, value, min_val, max_val)
    gfx.set(0.3, 0.3, 0.3, 1)
    gfx.rect(x, y, w, 20, 1)
    
    local norm_val = (value - min_val) / (max_val - min_val)
    gfx.set(0.6, 0.6, 0.8, 1)
    gfx.rect(x, y, w * norm_val, 20, 1)
    
    gfx.set(1, 1, 1, 1)
    gfx.x, gfx.y = x, y - 15
    gfx.drawstr(string.format("%s: %d", label, value))
    
    if gfx.mouse_cap & 1 == 1 and gfx.mouse_x >= x and gfx.mouse_x <= x+w and gfx.mouse_y >= y and gfx.mouse_y <= y+20 then
        local new_norm = (gfx.mouse_x - x) / w
        return math.floor(min_val + new_norm * (max_val - min_val))
    end
    return value
end

function main()
    if not gfx.getchar() or gfx.getchar() < 0 then return end
    
    -- Clear background
    gfx.set(0.1, 0.1, 0.1, 1)
    gfx.rect(0, 0, window_w, window_h, 1)
    
    -- Title
    gfx.set(1, 1, 1, 1)
    gfx.x, gfx.y = 10, 10
    gfx.drawstr("MIDI Melody Generator & Editor")
    
    local take = get_selected_midi_take()
    local y_pos = 40
    
    if take then
        local notes = get_notes(take)
        
        -- Display current notes
        gfx.x, gfx.y = 10, y_pos
        gfx.drawstr(string.format("Current MIDI Item - %d notes:", #notes))
        y_pos = y_pos + 25
        
        -- Notes list with scroll
        local list_height = 200
        local visible_notes = math.floor(list_height / 20)
        local start_note = math.floor(scroll_y / 20)
        
        gfx.set(0.2, 0.2, 0.2, 1)
        gfx.rect(10, y_pos, 580, list_height, 1)
        
        for i = 1, math.min(visible_notes, #notes - start_note) do
            local note_idx = start_note + i
            if note_idx <= #notes then
                local n = notes[note_idx]
                local note_y = y_pos + (i-1) * 20
                
                if note_idx == selected_note then
                    gfx.set(0.4, 0.4, 0.6, 1)
                    gfx.rect(10, note_y, 580, 20, 1)
                end
                
                gfx.set(1, 1, 1, 1)
                gfx.x, gfx.y = 15, note_y + 3
                gfx.drawstr(string.format("Note %d: Pitch %d, Velocity %d, Start %d, Length %d", 
                    note_idx, n.pitch, n.vel, n.startppq, n.length))
                
                -- Click to select note
                if gfx.mouse_cap & 1 == 1 and gfx.mouse_x >= 10 and gfx.mouse_x <= 590 and 
                   gfx.mouse_y >= note_y and gfx.mouse_y <= note_y + 20 then
                    selected_note = note_idx
                    edit_mode = true
                    new_pitch = n.pitch
                    new_velocity = n.vel
                    new_start = n.startppq
                    new_length = n.length
                end
            end
        end
        
        y_pos = y_pos + list_height + 20
        
        -- Edit controls
        if edit_mode and selected_note > 0 and selected_note <= #notes then
            gfx.set(1, 1, 1, 1)
            gfx.x, gfx.y = 10, y_pos
            gfx.drawstr("Edit Selected Note:")
            y_pos = y_pos + 20
            
            new_pitch = draw_slider(10, y_pos, 150, "Pitch", new_pitch, 0, 127)
            new_velocity = draw_slider(170, y_pos, 150, "Velocity", new_velocity, 1, 127)
            y_pos = y_pos + 40
            
            new_start = draw_slider(10, y_pos, 150, "Start", new_start, 0, 1920)
            new_length = draw_slider(170, y_pos, 150, "Length", new_length, 30, 480)
            y_pos = y_pos + 40
            
            -- Apply edit button
            if draw_button(10, y_pos, 100, 30, "Apply Edit", false) and gfx.mouse_cap & 1 == 1 then
                reaper.Undo_BeginBlock()
                edit_note(take, notes[selected_note].index, new_pitch, new_velocity, new_start, new_length)
                reaper.Undo_EndBlock("Edit MIDI Note", -1)
            end
            
            if draw_button(120, y_pos, 80, 30, "Cancel", false) and gfx.mouse_cap & 1 == 1 then
                edit_mode = false
                selected_note = -1
            end
            
            y_pos = y_pos + 40
        end
        
    else
        gfx.x, gfx.y = 10, y_pos
        gfx.drawstr("No MIDI item selected. Please select a MIDI item.")
        y_pos = y_pos + 25
    end
    
    -- Action buttons
    gfx.set(1, 1, 1, 1)
    gfx.x, gfx.y = 10, y_pos
    gfx.drawstr("Actions:")
    y_pos = y_pos + 25
    
    -- Generate new melody button
    if draw_button(10, y_pos, 150, 30, "Generate New Melody", take ~= nil) and gfx.mouse_cap & 1 == 1 and take then
        reaper.Undo_BeginBlock()
        insert_random_melody(take)
        reaper.Undo_EndBlock("Generate New MIDI Melody", -1)
        edit_mode = false
        selected_note = -1
    end
    
    -- Create new MIDI item button
    if draw_button(170, y_pos, 180, 30, "Create New MIDI Item", true) and gfx.mouse_cap & 1 == 1 then
        reaper.Undo_BeginBlock()
        create_new_midi_item()
        reaper.Undo_EndBlock("Create New MIDI Item", -1)
    end
    
    -- Clear all notes button
    if draw_button(360, y_pos, 120, 30, "Clear All Notes", take ~= nil) and gfx.mouse_cap & 1 == 1 and take then
        reaper.Undo_BeginBlock()
        reaper.MIDI_SelectAll(take, true)
        local _, note_count, _, _ = reaper.MIDI_CountEvts(take)
        for i = note_count-1, 0, -1 do
            reaper.MIDI_DeleteNote(take, i)
        end
        reaper.Undo_EndBlock("Clear All MIDI Notes", -1)
        edit_mode = false
        selected_note = -1
    end
    
    -- Handle mouse wheel for scrolling
    local mouse_wheel = gfx.mouse_wheel
    if mouse_wheel ~= 0 then
        scroll_y = scroll_y - mouse_wheel * 60
        scroll_y = math.max(0, scroll_y)
        gfx.mouse_wheel = 0
    end
    
    gfx.update()
    reaper.defer(main)
end

-- Initialize
gfx.init("MIDI Melody Generator & Editor", window_w, window_h)
main()
