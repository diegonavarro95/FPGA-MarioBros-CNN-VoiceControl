#include <SDL2/SDL.h>
#include <iostream>
#include "Vmario_vga_top.h"
#include "verilated.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vmario_vga_top* top = new Vmario_vga_top;

    SDL_Init(SDL_INIT_VIDEO);
    // Resolución real de la señal VGA generada
    SDL_Window* window = SDL_CreateWindow("FPGA - Emulador VGA Completo", 
                                          SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 
                                          640, 480, 0);
    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, 0);

    // Reset inicial
    top->rst = 1;
    top->clk = 0; top->eval();
    top->clk = 1; top->eval();
    top->rst = 0;

    bool quit = false;
    SDL_Event e;
    int camera_scroll = 0;
    bool prev_vsync = true;

    while (!quit) {
        // --- TICKS DEL RELOJ DE HARDWARE (1 ciclo de 25MHz) ---
        top->clk = 1; top->eval();
        top->clk = 0; top->eval();

        top->scroll_offset = camera_scroll;

        // Si el hardware dice que estamos en área visible, pintamos el píxel
        if (top->sim_video_on) {
            // Expandimos tus 4 bits (0-15) de hardware a formato C++ (0-255)
            // Multiplicando por 17 (0xF * 17 = 255) logramos el brillo exacto
            Uint8 r = top->vga_r * 17;
            Uint8 g = top->vga_g * 17;
            Uint8 b = top->vga_b * 17;

            SDL_SetRenderDrawColor(renderer, r, g, b, 255);
            SDL_RenderDrawPoint(renderer, top->sim_x, top->sim_y);
        }

        // --- DETECCIÓN DEL MONITOR ---
        // En el estándar VGA de 640x480, vsync es lógica negativa.
        // Cuando pasa de 1 a 0, significa que el haz de video volvió arriba (Frame terminado)
        if (prev_vsync == 1 && top->vsync == 0) {
            SDL_RenderPresent(renderer); // Mostrar el frame en pantalla
            
            // Procesar entradas solo 1 vez por frame (a 60Hz)
            while (SDL_PollEvent(&e)) {
                if (e.type == SDL_QUIT) quit = true;
                else if (e.type == SDL_KEYDOWN) {
                    if (e.key.keysym.sym == SDLK_RIGHT) camera_scroll++;
                    if (e.key.keysym.sym == SDLK_LEFT && camera_scroll > 0) camera_scroll--;
                }
            }
        }
        prev_vsync = top->vsync;
    }

    top->final();
    delete top;
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
} 