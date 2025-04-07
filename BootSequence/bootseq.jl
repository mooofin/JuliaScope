# --- Configuration for Animation ---
const BOX_WIDTH = 38 # Width inside the box borders
const TEXT_LINES = [
    "      Subdomain Finder          ",
    "      Powered by crt.sh         ",
    "         Author: Muffin         "
]
const BOX_CHARS = Dict(
    :topLeft => '╔', :topRight => '╗',
    :bottomLeft => '╚', :bottomRight => '╝',
    :horizontal => '═', :vertical => '║'
)
const SPINNER_CHARS = ['|', '/', '-', '\\']
const CRAYON_STYLE = Crayons.crayon"bold blue"
# --- Helper Function for Animation ---
"""Pads text to the specified width, centering it."""
function pad_center(text::String, width::Int)
    padding_total = max(0, width - length(text))
    padding_left = padding_total ÷ 2
    padding_right = padding_total - padding_left
    return ' '^padding_left * text * ' '^padding_right
end
# --- Main Animation Function ---
function animate_loading_logo(
    box_delay::Float64 = 0.005,
    spin_delay::Float64 = 0.1,
    text_delay::Float64 = 0.015,
    spin_cycles::Int = 15
)
    num_text_lines = length(TEXT_LINES)
    total_height = num_text_lines + 2

    # Draw box outline
    println(CRAYON_STYLE, BOX_CHARS[:topLeft] * repeat(BOX_CHARS[:horizontal], BOX_WIDTH) * BOX_CHARS[:topRight])
    flush(stdout)
    sleep(box_delay * BOX_WIDTH)

    empty_line_content = ' '^BOX_WIDTH
    empty_full_line = BOX_CHARS[:vertical] * empty_line_content * BOX_CHARS[:vertical]

    for _ in 1:num_text_lines
        println(CRAYON_STYLE, empty_full_line)
        flush(stdout)
        sleep(box_delay)
    end

    println(CRAYON_STYLE, BOX_CHARS[:bottomLeft] * repeat(BOX_CHARS[:horizontal], BOX_WIDTH) * BOX_CHARS[:bottomRight])
    flush(stdout)
    sleep(box_delay)

    # Spinner animation
    for i in 1:spin_cycles
        spinner_char = SPINNER_CHARS[(i-1) % length(SPINNER_CHARS) + 1]
        target_line_index = ceil(Int, num_text_lines / 2)

        for j in 1:num_text_lines
            print("\r")
            flush(stdout)
            line_content = if j == target_line_index
                pad_center(string(spinner_char), BOX_WIDTH)
            else
                ' '^BOX_WIDTH
            end
            println(CRAYON_STYLE, BOX_CHARS[:vertical] * line_content * BOX_CHARS[:vertical])
            flush(stdout)
        end
        sleep(spin_delay)
    end

    # Reveal text
    for j in 1:num_text_lines
        print("\r")
        print(CRAYON_STYLE, BOX_CHARS[:vertical])
        flush(stdout)
        sleep(text_delay)

        current_text = pad_center(TEXT_LINES[j], BOX_WIDTH)
        for char in current_text
            print(CRAYON_STYLE, char)
            flush(stdout)
            sleep(text_delay)
        end

        println(CRAYON_STYLE, BOX_CHARS[:vertical])
        flush(stdout)
        sleep(text_delay)
    end
    println()
end
