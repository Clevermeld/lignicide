/*
    Lignicide
    Copyright (c) 2025-2025 Clevermeld™ LLC

    TODO: Document.
*/

use bevy::prelude::*;
use bevy::render::render_resource::AsBindGroup;
use bevy::shader::ShaderRef;
use bevy::sprite_render::{Material2d, Material2dPlugin};
use bevy_pancam::PanCam;
use bevy_pancam::PanCamPlugin;

/// TODO: Document.
#[derive(Asset, TypePath, AsBindGroup, Debug, Clone)]
pub struct TileMaterial {
    #[uniform(0)]
    pub seed: f32,
}

impl Material2d for TileMaterial {
    fn fragment_shader() -> ShaderRef {
        "test.wgsl".into()
    }
}

/// Marker component for the tile entity
#[derive(Component)]
pub struct TileEntity;

/// Resource to store current seed
#[derive(Resource)]
pub struct CurrentSeed(pub f32);

/// TODO: Document.
fn main() {
    App::new()
        // Add external plugins.
        .add_plugins((DefaultPlugins, PanCamPlugin))
        .add_plugins(Material2dPlugin::<TileMaterial>::default())
        .insert_resource(CurrentSeed(0.0))
        .add_systems(Startup, spawn_tiles)
        .add_systems(Startup, setup_ui)
        .add_systems(Update, handle_seed_buttons)
        // Camera.
        .add_systems(Startup, |mut commands: Commands| {
            commands.spawn((Camera2d, IsDefaultUiCamera, PanCam::default()));
        })
        // Start the app.
        .run();
}

fn spawn_tiles(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<TileMaterial>>,
    seed: Res<CurrentSeed>,
) {
    // Spawn a quad with our tile material
    // 1024x1024 pixels = 256 tiles × 4 pixels per tile
    commands.spawn((
        Mesh2d(meshes.add(Rectangle::default())),
        MeshMaterial2d(materials.add(TileMaterial { seed: seed.0 })),
        Transform::from_scale(Vec3::new(1024.0, 1024.0, 1.0)),
        TileEntity,
    ));
}

#[derive(Component)]
struct SeedButton(i32);

#[derive(Component)]
struct SeedText;

fn setup_ui(mut commands: Commands) {
    commands
        .spawn(Node {
            position_type: PositionType::Absolute,
            top: Val::Px(10.0),
            left: Val::Px(10.0),
            flex_direction: FlexDirection::Column,
            row_gap: Val::Px(5.0),
            ..default()
        })
        .with_children(|parent| {
            // Seed display
            parent.spawn((
                Text::new("Seed: 0"),
                TextFont {
                    font_size: 24.0,
                    ..default()
                },
                TextColor(Color::WHITE),
                SeedText,
            ));

            // Button container
            parent
                .spawn(Node {
                    flex_direction: FlexDirection::Row,
                    column_gap: Val::Px(5.0),
                    ..default()
                })
                .with_children(|parent| {
                    // Previous button
                    parent
                        .spawn((
                            Button,
                            Node {
                                padding: UiRect::all(Val::Px(10.0)),
                                ..default()
                            },
                            BackgroundColor(Color::srgb(0.2, 0.2, 0.2)),
                            SeedButton(-1),
                        ))
                        .with_child((
                            Text::new("< Prev"),
                            TextFont {
                                font_size: 20.0,
                                ..default()
                            },
                            TextColor(Color::WHITE),
                        ));

                    // Next button
                    parent
                        .spawn((
                            Button,
                            Node {
                                padding: UiRect::all(Val::Px(10.0)),
                                ..default()
                            },
                            BackgroundColor(Color::srgb(0.2, 0.2, 0.2)),
                            SeedButton(1),
                        ))
                        .with_child((
                            Text::new("Next >"),
                            TextFont {
                                font_size: 20.0,
                                ..default()
                            },
                            TextColor(Color::WHITE),
                        ));
                });
        });
}

fn handle_seed_buttons(
    mut interaction_query: Query<(&Interaction, &SeedButton, &mut BackgroundColor), Changed<Interaction>>,
    mut seed: ResMut<CurrentSeed>,
    mut text_query: Query<&mut Text, With<SeedText>>,
    tile_query: Query<&MeshMaterial2d<TileMaterial>, With<TileEntity>>,
    mut materials: ResMut<Assets<TileMaterial>>,
) {
    for (interaction, button, mut bg_color) in &mut interaction_query {
        match *interaction {
            Interaction::Pressed => {
                seed.0 += button.0 as f32;

                // Update text
                if let Ok(mut text) = text_query.single_mut() {
                    text.0 = format!("Seed: {}", seed.0 as i32);
                }

                // Update material
                if let Ok(material_handle) = tile_query.single() {
                    if let Some(material) = materials.get_mut(&material_handle.0) {
                        material.seed = seed.0;
                    }
                }

                *bg_color = BackgroundColor(Color::srgb(0.4, 0.4, 0.4));
            }
            Interaction::Hovered => {
                *bg_color = BackgroundColor(Color::srgb(0.3, 0.3, 0.3));
            }
            Interaction::None => {
                *bg_color = BackgroundColor(Color::srgb(0.2, 0.2, 0.2));
            }
        }
    }
}
