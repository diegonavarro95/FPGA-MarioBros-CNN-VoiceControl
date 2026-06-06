#include <SDL2/SDL.h>
#include <iostream>
#include "Vsim_top_mario.h"
#include "verilated.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vsim_top_mario* top = new Vsim_top_mario;

    SDL_Init(SDL_INIT_VIDEO);
    SDL_Window* window = SDL_CreateWindow("FPGA Super Mario Bros - Nivel 1-1", 
                                          SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 
                                          640, 480, 0);
    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, 0);

    // Reinicio asíncrono
    top->reset = 1;
    top->clk_25mhz = 0; top->eval();
    top->clk_25mhz = 1; top->eval();
    top->reset = 0;

    bool quit = false;
    SDL_Event e;
    bool prev_vsync = true;

    // Estado de los botones de la FPGA
    top->btn_left = 0;
    top->btn_right = 0;

    while (!quit) {
        // Generar flancos del reloj
        top->clk_25mhz = 1; top->eval();
        top->clk_25mhz = 0; top->eval();

        // Si el hardware indica zona de dibujo, renderizar el píxel
        if (top->video_on_out) {
            Uint32 rgb = top->rgb_24_out;
            Uint8 r = (rgb >> 16) & 0xFF;
            Uint8 g = (rgb >> 8) & 0xFF;
            Uint8 b = rgb & 0xFF;

            SDL_SetRenderDrawColor(renderer, r, g, b, 255);
            SDL_RenderDrawPoint(renderer, top->sim_x, top->sim_y);
        }

        // Refresco de pantalla al final del frame (VSYNC cae)
        if (prev_vsync == 1 && top->vsync == 0) {
            SDL_RenderPresent(renderer);
            
            // Leer teclado para controlar el mapa
            while (SDL_PollEvent(&e)) {
                if (e.type == SDL_QUIT) quit = true;
                else if (e.type == SDL_KEYDOWN || e.type == SDL_KEYUP) {
                    bool isPressed = (e.type == SDL_KEYDOWN);
                    if (e.key.keysym.sym == SDLK_RIGHT) top->btn_right = isPressed;
                    if (e.key.keysym.sym == SDLK_LEFT)  top->btn_left = isPressed;
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