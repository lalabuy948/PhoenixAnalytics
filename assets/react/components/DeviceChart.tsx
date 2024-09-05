"use client";

import * as React from "react";
import { format } from "date-fns";
import { Label, Pie, PieChart } from "recharts";
import { nFormatter } from "@/lib/utils";

import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";

import {
  ChartConfig,
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
} from "@/components/ui/chart";

import { DateRange } from "./DateRange";

const chartConfig = {
  visits: {
    label: "Visits",
  },
  desktop: {
    label: "Desktop",
    color: "hsl(var(--chart-1))",
  },
  tablet: {
    label: "Tablet",
    color: "hsl(var(--chart-2))",
  },
  mobile: {
    label: "Mobile",
    color: "hsl(var(--chart-3))",
  },
} satisfies ChartConfig;

type ChartData = {
  device: string;
  visits: number;
  fill: string;
};

export function DeviceChart({
  chartData,
  dateRange,
}: {
  chartData: ChartData[];
  dateRange: DateRange;
}) {
  chartData.forEach((item) => {
    item.fill = `var(--color-${item.device})`;
  });

  return (
    <Card className="flex flex-col">
      <CardHeader>
        <CardTitle>Device Usage</CardTitle>
        <CardDescription>
          {format(dateRange.from, "dd LLL, y")} -{" "}
          {format(dateRange.to, "dd LLL, y")}
        </CardDescription>
      </CardHeader>
      <CardContent className="flex-1 pb-0">
        <ChartContainer
          config={chartConfig}
          className="mx-auto aspect-square max-h-[250px]"
        >
          <PieChart>
            <ChartTooltip
              cursor={false}
              content={
                <ChartTooltipContent
                  className="w-[150px]"
                  hideLabel
                  indicator="dashed"
                />
              }
            />
            <Pie
              data={chartData}
              dataKey="visits"
              nameKey="device"
              innerRadius={60}
              strokeWidth={5}
            >
              <Label
                content={({ viewBox }) => {
                  if (viewBox && "cx" in viewBox && "cy" in viewBox) {
                    return (
                      <text
                        x={viewBox.cx}
                        y={viewBox.cy}
                        textAnchor="middle"
                        dominantBaseline="middle"
                      >
                        <tspan
                          x={viewBox.cx}
                          y={viewBox.cy}
                          className="fill-foreground text-3xl font-bold"
                        >
                          {nFormatter(
                            chartData.reduce(
                              (sum, item) => sum + item.visits,
                              0,
                            ),
                            1,
                          )}
                        </tspan>
                        <tspan
                          x={viewBox.cx}
                          y={(viewBox.cy || 0) + 24}
                          className="fill-muted-foreground"
                        >
                          Visits
                        </tspan>
                      </text>
                    );
                  }
                }}
              />
            </Pie>
          </PieChart>
        </ChartContainer>
      </CardContent>
      <CardFooter className="flex-col items-start gap-2 text-sm mt-2">
        <div className="leading-none text-muted-foreground">
          Showing total visits split by device type
        </div>
      </CardFooter>
    </Card>
  );
}
