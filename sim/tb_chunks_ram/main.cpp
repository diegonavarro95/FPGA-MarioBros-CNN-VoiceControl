#include <SDL2/SDL.h>
#include <iostream>
#include "VCtop.h"
#include "verilated.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    VCtop* top = new VCtop;

    SDL_Init(SDL_INIT_VIDEO);
    SDL_Window* window = SDL_CreateWindow("FPGA Super Mario Bros - ROM Sim", 
                                          SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 
                                          320, 320, 0);
    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, 0);
    SDL_RenderSetScale(renderer, 20.0, 20.0); 

    // 1. EL FIX DEL RESET: Sostener RST en alto durante 4 ciclos de reloj
    top->RST = 1;
    for(int i = 0; i < 4; i++) {
        top->CLK = 1; top->eval();
        top->CLK = 0; top->eval();
    }
    top->RST = 0; // Ahora sí, el LFSR tiene la semilla 10010110

    bool quit = false;
    SDL_Event e;

    // 2. EL FIX DEL DESFASE: Memorizar el ciclo anterior (Pipeline de 1 ciclo)
    int draw_x = 0;
    int draw_y = 0;
    bool can_draw = false;

    while (!quit) {
        while (SDL_PollEvent(&e)) {
            if (e.type == SDL_QUIT) quit = true;
        }

        // --- FLANCO DE SUBIDA ---
        top->CLK = 1;
        top->eval();

        // Leer la salida de este ciclo
        int current_x = top->out_x;
        int current_y = top->out_y;
        int color_3bit = top->RAM_DATA_OUT;

        // Decodificar RGB
        Uint8 r = (color_3bit & 0b100) ? 255 : 0;
        Uint8 g = (color_3bit & 0b010) ? 255 : 0;
        Uint8 b = (color_3bit & 0b001) ? 255 : 0;

        // Dibujar el píxel del ciclo ANTERIOR en la coordenada correcta
        if (can_draw) {
            SDL_SetRenderDrawColor(renderer, r, g, b, 255);
            SDL_RenderDrawPoint(renderer, draw_x, draw_y);
        }

        // Memorizar para el próximo ciclo
        draw_x = current_x;
        draw_y = current_y;
        can_draw = true;

        // --- FLANCO DE BAJADA ---
        top->CLK = 0;
        top->eval();

        // Refrescar pantalla cuando se termina el bloque de 16x16
        if (draw_x == 15 && draw_y == 15) {
            SDL_RenderPresent(renderer);
            SDL_Delay(500); // 500 ms de pausa para ver el bloque actual
            
            SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
            SDL_RenderClear(renderer);
            can_draw = false; // Pausar dibujo un ciclo por el cambio de contexto
        }
    }

    top->final();
    delete top;
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}