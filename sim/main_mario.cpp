#include <SDL2/SDL.h>
#include <iostream>
#include "Vsim_top_mario.h"
#include "verilated.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vsim_top_mario* top = new Vsim_top_mario;

    SDL_Init(SDL_INIT_VIDEO);
    SDL_Window* window = SDL_CreateWindow("FPGA Super Mario Bros - Gameplay a 60 FPS", 
                                          SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 
                                          640, 480, 0);
    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    
    // FIX 1: Crear una textura en VRAM para dibujar todo el frame de golpe
    SDL_Texture* texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, 640, 480);
    Uint32* pixels = new Uint32[640 * 480];

    top->reset = 1;
    top->clk_25mhz = 0; top->eval();
    top->clk_25mhz = 1; top->eval();
    top->reset = 0;

    bool quit = false;
    SDL_Event e;
    bool prev_vsync = true;

    top->btn_left = 0; top->btn_right = 0;
    top->btn_jump = 0; top->btn_run = 0;

    while (!quit) {
        top->clk_25mhz = 1; top->eval();
        top->clk_25mhz = 0; top->eval();

        // Acumular píxeles en la memoria RAM primero (Extremadamente rápido)
        if (top->video_on_out) {
            if (top->sim_x < 640 && top->sim_y < 480) {
                // Formato ARGB: 0xFF000000 fuerza la opacidad completa
                pixels[top->sim_y * 640 + top->sim_x] = 0xFF000000 | top->rgb_24_out;
            }
        }

        // Flanco de bajada (Fin del frame)
        if (prev_vsync == 1 && top->vsync == 0) {
            // Mandar el buffer entero a la tarjeta gráfica y dibujar
            SDL_UpdateTexture(texture, NULL, pixels, 640 * sizeof(Uint32));
            SDL_RenderClear(renderer);
            SDL_RenderCopy(renderer, texture, NULL, NULL);
            SDL_RenderPresent(renderer);
            
            while (SDL_PollEvent(&e)) {
                if (e.type == SDL_QUIT) quit = true;
                else if (e.type == SDL_KEYDOWN || e.type == SDL_KEYUP) {
                    bool isPressed = (e.type == SDL_KEYDOWN);
                    if (e.key.keysym.sym == SDLK_d || e.key.keysym.sym == SDLK_RIGHT) top->btn_right = isPressed;
                    if (e.key.keysym.sym == SDLK_a || e.key.keysym.sym == SDLK_LEFT)  top->btn_left = isPressed;
                    if (e.key.keysym.sym == SDLK_SPACE) top->btn_jump = isPressed;
                    if (e.key.keysym.sym == SDLK_LSHIFT) top->btn_run = isPressed;
                }
            }
        }
        prev_vsync = top->vsync;
    }

    top->final();
    delete top;
    delete[] pixels;
    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}